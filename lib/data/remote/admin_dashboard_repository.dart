import 'package:supabase_flutter/supabase_flutter.dart';

class AdminDashboardRepository {
  const AdminDashboardRepository(this.client);

  final SupabaseClient client;

  Future<AdminDashboardSummary> getSummary() async {
    final user = client.auth.currentUser;
    if (user == null) throw const AuthException('Please log in again.');

    final eventRows = await client
        .from('donation_events')
        .select('id, status, starts_at')
        .eq('created_by', user.id);
    final now = DateTime.now().toUtc();
    final upcomingCount = eventRows.where((event) {
      return event['status'] == 'upcoming' &&
          DateTime.parse(event['starts_at']! as String).toUtc().isAfter(now);
    }).length;
    final eventIds = eventRows.map((event) => event['id']! as String).toList();

    var registrationCount = 0;
    if (eventIds.isNotEmpty) {
      final registrationRows = await client
          .from('event_registrations')
          .select('id')
          .inFilter('event_id', eventIds)
          .neq('status', 'cancelled');
      registrationCount = registrationRows.length;
    }

    return AdminDashboardSummary(
      upcomingEvents: upcomingCount,
      donorRegistrations: registrationCount,
    );
  }
}

class AdminDashboardSummary {
  const AdminDashboardSummary({
    required this.upcomingEvents,
    required this.donorRegistrations,
  });

  final int upcomingEvents;
  final int donorRegistrations;
}
