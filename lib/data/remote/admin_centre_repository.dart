import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/donation_centre.dart';

class AdminCentreRepository {
  const AdminCentreRepository(this.client);

  final SupabaseClient client;

  Future<List<DonationCentre>> getCentres() async {
    final rows = await client.from('donation_centres').select().order('name');
    return rows.map(DonationCentre.fromMap).toList();
  }

  Future<void> create({
    required String name,
    required String address,
    required String state,
    required double latitude,
    required double longitude,
    required String operatingHours,
  }) async {
    await client.from('donation_centres').insert({
      'name': name,
      'address': address,
      'state': state,
      'latitude': latitude,
      'longitude': longitude,
      'operating_hours': operatingHours.isEmpty ? null : operatingHours,
    });
  }

  Future<void> update({
    required String id,
    required String name,
    required String address,
    required String state,
    required double latitude,
    required double longitude,
    required String operatingHours,
  }) async {
    await client
        .from('donation_centres')
        .update({
          'name': name,
          'address': address,
          'state': state,
          'latitude': latitude,
          'longitude': longitude,
          'operating_hours': operatingHours.isEmpty ? null : operatingHours,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', id);
  }
}
