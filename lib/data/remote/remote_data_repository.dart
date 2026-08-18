import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/donation_centre.dart';
import '../../models/donation_event.dart';

class RemoteDataRepository {
  const RemoteDataRepository(this.client);

  final SupabaseClient client;

  Future<List<DonationCentre>> getCentres() async {
    final rows = await client.from('donation_centres').select().order('name');
    return rows.map(DonationCentre.fromMap).toList();
  }

  Future<List<DonationEvent>> getEvents() async {
    final rows = await client
        .from('donation_events')
        .select()
        .neq('status', 'cancelled')
        .order('starts_at');
    return rows.map(DonationEvent.fromMap).toList();
  }
}
