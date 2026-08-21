import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/donation_event.dart';

class AdminEventRepository {
  const AdminEventRepository(this.client);

  final SupabaseClient client;

  Future<List<DonationEvent>> getOwnEvents() async {
    final user = client.auth.currentUser;
    if (user == null) throw const AuthException('Please log in again.');
    final rows = await client
        .from('donation_events')
        .select()
        .eq('created_by', user.id)
        .order('starts_at', ascending: false);
    return rows.map(DonationEvent.fromMap).toList();
  }

  Future<void> create({
    required String title,
    required String venue,
    required DateTime startsAt,
    required DateTime endsAt,
    required String description,
  }) async {
    final user = client.auth.currentUser;
    if (user == null) throw const AuthException('Please log in again.');
    await client.from('donation_events').insert({
      'title': title,
      'venue': venue,
      'starts_at': startsAt.toUtc().toIso8601String(),
      'ends_at': endsAt.toUtc().toIso8601String(),
      'description': description.isEmpty ? null : description,
      'status': 'upcoming',
      'created_by': user.id,
    });
  }

  Future<void> update({
    required String id,
    required String title,
    required String venue,
    required DateTime startsAt,
    required DateTime endsAt,
    required String description,
  }) async {
    await client
        .from('donation_events')
        .update({
          'title': title,
          'venue': venue,
          'starts_at': startsAt.toUtc().toIso8601String(),
          'ends_at': endsAt.toUtc().toIso8601String(),
          'description': description.isEmpty ? null : description,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', id);
  }

  Future<void> cancel(String id) async {
    await client
        .from('donation_events')
        .update({
          'status': 'cancelled',
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', id);
  }
}
