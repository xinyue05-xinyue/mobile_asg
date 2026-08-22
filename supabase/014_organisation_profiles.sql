create table if not exists public.organisation_profiles (
  owner_id uuid primary key references public.profiles(id) on delete cascade,
  display_name text not null,
  contact_phone text,
  address text,
  description text,
  latitude double precision,
  longitude double precision,
  image_path text,
  updated_at timestamptz not null default now()
);

alter table public.organisation_profiles enable row level security;
grant select, insert, update on public.organisation_profiles to authenticated;

drop policy if exists organisation_profiles_read on public.organisation_profiles;
create policy organisation_profiles_read on public.organisation_profiles
for select to authenticated using (true);

drop policy if exists organisation_profiles_owner_insert on public.organisation_profiles;
create policy organisation_profiles_owner_insert on public.organisation_profiles
for insert to authenticated
with check (
  owner_id = auth.uid()
  and exists (
    select 1 from public.profiles
    where id = auth.uid()
      and role::text in ('admin', 'hospital', 'hospital_admin')
  )
);

drop policy if exists organisation_profiles_owner_update on public.organisation_profiles;
create policy organisation_profiles_owner_update on public.organisation_profiles
for update to authenticated
using (owner_id = auth.uid() or public.is_system_admin())
with check (owner_id = auth.uid() or public.is_system_admin());

insert into public.organisation_profiles (owner_id, display_name)
select distinct on (request.user_id)
  request.user_id,
  request.organisation_name
from public.role_requests request
where request.status = 'approved'
order by request.user_id, request.reviewed_at desc nulls last
on conflict (owner_id) do nothing;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'organisation-images',
  'organisation-images',
  true,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update
set public = excluded.public,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists organisation_images_owner_insert on storage.objects;
create policy organisation_images_owner_insert on storage.objects
for insert to authenticated
with check (
  bucket_id = 'organisation-images'
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists organisation_images_owner_update on storage.objects;
create policy organisation_images_owner_update on storage.objects
for update to authenticated
using (
  bucket_id = 'organisation-images'
  and (storage.foldername(name))[1] = auth.uid()::text
)
with check (
  bucket_id = 'organisation-images'
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists organisation_images_owner_delete on storage.objects;
create policy organisation_images_owner_delete on storage.objects
for delete to authenticated
using (
  bucket_id = 'organisation-images'
  and (storage.foldername(name))[1] = auth.uid()::text
);
