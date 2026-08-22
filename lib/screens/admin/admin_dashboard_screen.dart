import 'package:flutter/material.dart';

import '../../data/remote/supabase_service.dart';
import '../../widgets/notification_button.dart';
import '../login_screen.dart';
import '../statistics_screen.dart';
import 'manage_centres_screen.dart';
import 'manage_events_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Organisation Admin'),
        actions: [
          const StatisticsIconButton(),
          const NotificationButton(),
          IconButton(
            onPressed: () async {
              await SupabaseService.client?.auth.signOut();
              if (!context.mounted) return;
              await Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (_) => false,
              );
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Dashboard', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 16),
          const Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  label: 'Upcoming events',
                  value: '0',
                  icon: Icons.event_outlined,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _SummaryCard(
                  label: 'Donor registrations',
                  value: '0',
                  icon: Icons.fact_check_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ManageEventsScreen()),
            ),
            icon: const Icon(Icons.event_outlined),
            label: const Text('Manage donation events'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ManageCentresScreen()),
            ),
            icon: const Icon(Icons.location_on_outlined),
            label: const Text('Manage donation centres'),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text(value, style: Theme.of(context).textTheme.headlineMedium),
            Text(label),
          ],
        ),
      ),
    );
  }
}
