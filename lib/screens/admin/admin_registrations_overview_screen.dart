import 'package:flutter/material.dart';
import '../../widgets/event_schedule.dart';

import '../../app/theme/app_theme.dart';
import '../../data/remote/admin_dashboard_repository.dart';
import '../../data/remote/supabase_service.dart';

class AdminRegistrationsOverviewScreen extends StatelessWidget {
  const AdminRegistrationsOverviewScreen({super.key});

  String dateLabel(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day/$month/${value.year}';
  }

  Future<List<AdminRegistrationDetail>> load() {
    final client = SupabaseService.client;
    if (client == null) return Future.value(const []);
    return AdminDashboardRepository(client).getRegistrationDetails();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.organisationBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.organisationHeader,
        foregroundColor: Colors.white,
        titleTextStyle: AppTheme.organisationHeaderTitleStyle,
        title: const Text('Donor registrations'),
      ),
      body: FutureBuilder<List<AdminRegistrationDetail>>(
        future: load(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Unable to load registrations: ${snapshot.error}'),
            );
          }
          final items = snapshot.data ?? const [];
          if (items.isEmpty) {
            return const Center(child: Text('No donor registrations yet.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = items[index];
              return Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(child: Text(item.bloodType ?? '?')),
                  title: Text(item.donorName),
                  subtitle: Text(
                    '${item.eventTitle}\n'
                    '${eventSchedule(item.eventStartsAt, item.eventEndsAt)}\nStatus: ${item.status}',
                  ),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
