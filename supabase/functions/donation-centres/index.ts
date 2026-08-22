import {
  parquetReadObjects,
} from "npm:hyparquet@1.29.1";
import { compressors } from "npm:hyparquet-compressors@1.1.1";

const sourceUrl =
  "https://raw.githubusercontent.com/MoH-Malaysia/kkmnow-data/main/blood_05_map_facility.parquet";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

const addressCache = new Map<string, string>();
const searchCache = new Map<string, { lat: number; lon: number; address: string }>();
let geocodeQueue = Promise.resolve();
let lastGeocodeAt = 0;

function reverseAddress(lat: number, lon: number): Promise<string> {
  const key = `${lat.toFixed(6)},${lon.toFixed(6)}`;
  const cached = addressCache.get(key);
  if (cached) return Promise.resolve(cached);

  const task = geocodeQueue.then(async () => {
    const waitMs = Math.max(0, 1000 - (Date.now() - lastGeocodeAt));
    if (waitMs > 0) await new Promise((resolve) => setTimeout(resolve, waitMs));

    const url = new URL("https://nominatim.openstreetmap.org/reverse");
    url.searchParams.set("format", "jsonv2");
    url.searchParams.set("lat", String(lat));
    url.searchParams.set("lon", String(lon));
    url.searchParams.set("zoom", "18");
    url.searchParams.set("addressdetails", "0");
    url.searchParams.set("layer", "address");

    lastGeocodeAt = Date.now();
    const response = await fetch(url, {
      headers: {
        "User-Agent": "MyDarah/1.0 (blood donation student application)",
        "Referer": "https://gsjcocwsvlbuizxpuzqo.supabase.co/",
      },
    });
    if (!response.ok) throw new Error(`Address lookup returned ${response.status}`);

    const payload = await response.json();
    const address = String(payload.display_name ?? "Address unavailable");
    addressCache.set(key, address);
    return address;
  });
  geocodeQueue = task.then(() => undefined, () => undefined);
  return task;
}

function searchLocation(query: string): Promise<{ lat: number; lon: number; address: string }> {
  const key = query.trim().toLowerCase();
  const cached = searchCache.get(key);
  if (cached) return Promise.resolve(cached);

  const task = geocodeQueue.then(async () => {
    const waitMs = Math.max(0, 1000 - (Date.now() - lastGeocodeAt));
    if (waitMs > 0) await new Promise((resolve) => setTimeout(resolve, waitMs));
    const url = new URL("https://nominatim.openstreetmap.org/search");
    url.searchParams.set("format", "jsonv2");
    url.searchParams.set("q", query);
    url.searchParams.set("limit", "1");
    url.searchParams.set("countrycodes", "my");
    lastGeocodeAt = Date.now();
    const response = await fetch(url, {
      headers: {
        "User-Agent": "MyDarah/1.0 (blood donation student application)",
        "Referer": "https://gsjcocwsvlbuizxpuzqo.supabase.co/",
      },
    });
    if (!response.ok) throw new Error(`Location search returned ${response.status}`);
    const rows = await response.json();
    if (!Array.isArray(rows) || rows.length === 0) throw new Error("Location not found");
    const result = {
      lat: Number(rows[0].lat),
      lon: Number(rows[0].lon),
      address: String(rows[0].display_name ?? query),
    };
    searchCache.set(key, result);
    return result;
  });
  geocodeQueue = task.then(() => undefined, () => undefined);
  return task;
}

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    if (request.method === "POST") {
      const body = await request.clone().json().catch(() => ({}));
      if (body.action === "reverse") {
        const lat = Number(body.lat);
        const lon = Number(body.lon);
        if (!Number.isFinite(lat) || !Number.isFinite(lon)) {
          return Response.json(
            { error: "Valid lat and lon are required" },
            { status: 400, headers: corsHeaders },
          );
        }
        const address = await reverseAddress(lat, lon);
        return Response.json(
          { address, attribution: "© OpenStreetMap contributors" },
          {
            headers: {
              ...corsHeaders,
              "Cache-Control": "public, max-age=86400",
            },
          },
        );
      }
      if (body.action === "search") {
        const query = String(body.query ?? "").trim();
        if (query.length < 3) {
          return Response.json(
            { error: "A location query is required" },
            { status: 400, headers: corsHeaders },
          );
        }
        const result = await searchLocation(query);
        return Response.json(
          { ...result, attribution: "© OpenStreetMap contributors" },
          { headers: { ...corsHeaders, "Cache-Control": "public, max-age=86400" } },
        );
      }
    }

    const upstream = await fetch(sourceUrl, {
      headers: { "User-Agent": "MyDarah/1.0" },
    });
    if (!upstream.ok) {
      throw new Error(`Official dataset returned ${upstream.status}`);
    }

    const file = await upstream.arrayBuffer();
    const rows = await parquetReadObjects({ file, compressors });
    const centres = rows.map((row) => ({
      hospital: String(row.hospital),
      state: String(row.state),
      lat: Number(row.lat),
      lon: Number(row.lon),
    }));

    return Response.json(
      {
        centres,
        source: sourceUrl,
        retrieved_at: new Date().toISOString(),
      },
      {
        headers: {
          ...corsHeaders,
          "Cache-Control": "public, max-age=3600",
        },
      },
    );
  } catch (error) {
    return Response.json(
      { error: error instanceof Error ? error.message : "Unknown error" },
      { status: 502, headers: corsHeaders },
    );
  }
});
