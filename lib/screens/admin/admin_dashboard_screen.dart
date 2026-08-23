import 'package:flutter/material.dart';

import '../../data/remote/admin_dashboard_repository.dart';
import '../../data/remote/supabase_service.dart';
import '../../widgets/notification_button.dart';
import '../../widgets/signed_in_identity_card.dart';
import '../login_screen.dart';
import '../statistics_screen.dart';
import '../staff_profile_screen.dart';
import 'manage_centres_screen.dart';
import 'manage_events_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late Future<AdminDashboardSummary> summary;

  @override
  void initState() {
    super.initState();
    summary = loadSummary();
  }

  Future<AdminDashboardSummary> loadSummary() {
    final client = SupabaseService.client;
    if (client == null) {
      return Future.value(
        const AdminDashboardSummary(upcomingEvents: 0, donorRegistrations: 0),
      );
    }
    return AdminDashboardRepository(client).getSummary();
  }

  Future<void> refresh() async {
    final refreshed = loadSummary();
    setState(() {
      summary = refreshed;
    });
    await refreshed;
  }

  Future<void> openEvents() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ManageEventsScreen()),
    );
    if (mounted) await refresh();
  }

  Future<void> openCentres() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ManageCentresScreen()),
    );
    if (mounted) await refresh();
  }

  Future<void> signOut() async {
    await SupabaseService.client?.auth.signOut();
    if (!mounted) return;
    await Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Organisation Admin'),
        actions: [
          IconButton(
            tooltip: 'My profile',
            icon: const Icon(Icons.person_outline),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    const StaffProfileScreen(roleLabel: 'Organisation admin'),
              ),
            ),
          ),
          const StatisticsIconButton(),
          const NotificationButton(),
          IconButton(
            onPressed: signOut,
            tooltip: 'Log out',
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: FutureBuilder<AdminDashboardSummary>(
        future: summary,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Unable to load dashboard information.'),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: refresh,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try again'),
                    ),
                  ],
                ),
              ),
            );
          }
          final value = snapshot.data!;
          return RefreshIndicator(
            onRefresh: refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                const SignedInIdentityCard(roleLabel: 'Organisation admin'),
                const SizedBox(height: 12),
                Text(
                  'Dashboard',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        label: 'Upcoming events',
                        value: '${value.upcomingEvents}',
                        icon: Icons.event_outlined,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SummaryCard(
                        label: 'Donor registrations',
                        value: '${value.donorRegistrations}',
                        icon: Icons.fact_check_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Live data from your organisation events in Supabase.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: openEvents,
                  icon: const Icon(Icons.event_outlined),
                  label: const Text('Manage donation events'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: openCentres,
                  icon: const Icon(Icons.location_on_outlined),
                  label: const Text('Manage donation centres'),
                ),
              ],
            ),
          );
        },
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
