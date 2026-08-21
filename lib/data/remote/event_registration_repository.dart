import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/event_registration.dart';

class EventRegistrationRepository {
  const EventRegistrationRepository(this.client);

  final SupabaseClient client;

  Future<Set<String>> getMyRegisteredEventIds() async {
    final user = client.auth.currentUser;
    if (user == null) return const {};
    final rows = await client
        .from('event_registrations')
        .select('event_id')
        .eq('donor_id', user.id)
        .eq('status', 'registered');
    return rows.map((row) => row['event_id']! as String).toSet();
  }

  Future<void> register(String eventId) async {
    final user = client.auth.currentUser;
    if (user == null) throw const AuthException('Please log in again.');
    await client.from('event_registrations').insert({
      'event_id': eventId,
      'donor_id': user.id,
    });
  }

  Future<List<EventRegistration>> getForEvent(String eventId) async {
    final rows = await client
        .from('event_registrations')
        .select(
          'id, event_id, donor_id, status, registered_at, '
          'donor:profiles!event_registrations_donor_id_fkey(full_name, blood_type)',
        )
        .eq('event_id', eventId)
        .order('registered_at');
    return rows.map(EventRegistration.fromMap).toList();
  }

  Future<void> verifyDonation({
    required String registrationId,
    required DateTime nextEligibleDate,
  }) async {
    await client.rpc(
      'verify_event_donation',
      params: {
        'p_registration_id': registrationId,
        'p_next_eligible_date': nextEligibleDate
            .toIso8601String()
            .split('T')
            .first,
      },
    );
  }
}
