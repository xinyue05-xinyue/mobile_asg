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

  Future<List<AdminRegistrationDetail>> getRegistrationDetails() async {
    final user = client.auth.currentUser;
    if (user == null) throw const AuthException('Please log in again.');
    final eventRows = await client
        .from('donation_events')
        .select('id, title, starts_at, ends_at')
        .eq('created_by', user.id);
    if (eventRows.isEmpty) return const [];
    final events = {
      for (final row in eventRows)
        row['id']! as String: (
          title: row['title']! as String,
          startsAt: DateTime.parse(row['starts_at']! as String).toLocal(),
          endsAt: DateTime.parse(row['ends_at']! as String).toLocal(),
        ),
    };
    final rows = await client
        .from('event_registrations')
        .select(
          'id, event_id, status, registered_at, '
          'donor:profiles!event_registrations_donor_id_fkey(full_name, blood_type)',
        )
        .inFilter('event_id', events.keys.toList())
        .neq('status', 'cancelled')
        .order('registered_at', ascending: false);
    return rows.map((row) {
      final donor = row['donor'] as Map<String, Object?>?;
      final event = events[row['event_id']! as String]!;
      return AdminRegistrationDetail(
        donorName: donor?['full_name'] as String? ?? 'Donor',
        bloodType: donor?['blood_type'] as String?,
        eventTitle: event.title,
        eventStartsAt: event.startsAt,
        eventEndsAt: event.endsAt,
        status: row['status']! as String,
        registeredAt: DateTime.parse(row['registered_at']! as String).toLocal(),
      );
    }).toList();
  }
}

class AdminRegistrationDetail {
  const AdminRegistrationDetail({
    required this.donorName,
    required this.eventTitle,
    required this.eventStartsAt,
    required this.eventEndsAt,
    required this.status,
    required this.registeredAt,
    this.bloodType,
  });

  final String donorName;
  final String? bloodType;
  final String eventTitle;
  final DateTime eventStartsAt;
  final DateTime eventEndsAt;
  final String status;
  final DateTime registeredAt;
}

class AdminDashboardSummary {
  const AdminDashboardSummary({
    required this.upcomingEvents,
    required this.donorRegistrations,
  });

  final int upcomingEvents;
  final int donorRegistrations;
}
