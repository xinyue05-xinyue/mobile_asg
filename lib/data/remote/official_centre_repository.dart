import '../../models/donation_centre.dart';
import 'supabase_service.dart';

class OfficialCentreRepository {
  const OfficialCentreRepository();

  Future<List<DonationCentre>> getCentres() async {
    final client = SupabaseService.client;
    if (client == null) {
      throw StateError('Supabase is not configured.');
    }

    final response = await client.functions.invoke('donation-centres');
    if (response.status < 200 || response.status >= 300) {
      throw StateError('Facility service returned ${response.status}.');
    }

    final payload = response.data;
    if (payload is! Map || payload['centres'] is! List) {
      throw const FormatException('Unexpected facility service response.');
    }

    return (payload['centres'] as List)
        .cast<Map<String, Object?>>()
        .map(DonationCentre.fromOfficialMap)
        .toList();
  }

  Future<String> getAddress(DonationCentre centre) async {
    final client = SupabaseService.client;
    if (client == null) {
      throw StateError('Supabase is not configured.');
    }

    final response = await client.functions.invoke(
      'donation-centres',
      body: {
        'action': 'reverse',
        'lat': centre.latitude,
        'lon': centre.longitude,
      },
    );
    if (response.status < 200 || response.status >= 300) {
      throw StateError('Address service returned ${response.status}.');
    }

    final payload = response.data;
    if (payload is! Map || payload['address'] is! String) {
      throw const FormatException('Unexpected address service response.');
    }
    return payload['address'] as String;
  }
}
