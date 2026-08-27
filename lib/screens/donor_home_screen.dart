import 'package:flutter/material.dart';

import '../data/remote/profile_repository.dart';
import '../data/remote/supabase_service.dart';
import '../models/profile_overview.dart';
import '../models/donor_level.dart';
import '../widgets/notification_button.dart';
import 'donor/donor_emergency_screen.dart';
import 'statistics_screen.dart';

class DonorHomeScreen extends StatefulWidget {
  const DonorHomeScreen({super.key, required this.onTabSelected});

  final ValueChanged<int> onTabSelected;

  @override
  State<DonorHomeScreen> createState() => _DonorHomeScreenState();
}

class _DonorHomeScreenState extends State<DonorHomeScreen> {
  Future<ProfileOverview?>? overview;

  @override
  void initState() {
    super.initState();
    overview = loadOverview();
  }

  Future<ProfileOverview?> loadOverview() {
    final client = SupabaseService.client;
    if (client == null) return Future.value(null);
    return ProfileRepository(client).getOverview();
  }

  Future<void> refresh() async {
    final refreshed = loadOverview();
    setState(() {
      overview = refreshed;
    });
    await refreshed;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('MyDarah'),
        actions: const [StatisticsIconButton(), NotificationButton()],
      ),
      body: FutureBuilder<ProfileOverview?>(
        future: overview,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          return RefreshIndicator(
            onRefresh: refresh,
            child: _HomeContent(
              overview: snapshot.data,
              hasError: snapshot.hasError,
              onTabSelected: widget.onTabSelected,
            ),
          );
        },
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({
    required this.overview,
    required this.hasError,
    required this.onTabSelected,
  });

  final ProfileOverview? overview;
  final bool hasError;
  final ValueChanged<int> onTabSelected;

  String eligibilityLabel(DateTime? date) {
    if (date == null || !date.isAfter(DateTime.now())) return 'Eligible now';
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return 'From $day/$month/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final profile = overview?.profile;
    final firstName = profile?.fullName.trim().split(RegExp(r'\s+')).first;
    final points = overview?.rewardPoints ?? 0;
    final donationCount = overview?.donations.length ?? 0;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Hi, ${firstName?.isNotEmpty == true ? firstName : 'Donor'} 👋',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 4),
        Text(
          hasError
              ? 'Some account information could not be loaded.'
              : 'Welcome back! Your donation journey matters.',
        ),
        const SizedBox(height: 20),
        Card(
          color: Theme.of(context).colorScheme.primary,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'You can save lives',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        profile?.bloodType == null
                            ? 'Set your blood type to receive matching alerts.'
                            : 'Blood type ${profile!.bloodType} donor',
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        eligibilityLabel(profile?.nextEligibleDate),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.bloodtype, size: 70, color: Colors.white),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: 'Donations',
                value: '${overview?.donations.length ?? 0}',
                onTap: () => onTabSelected(3),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MetricCard(
                label: 'Points',
                value: '$points',
                onTap: () => onTabSelected(3),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MetricCard(
                label: 'Level',
                value: DonorLevel.name(donationCount, short: true),
                onTap: () => onTabSelected(3),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DonorEmergencyScreen()),
            ),
            leading: const Icon(Icons.emergency_outlined, color: Colors.red),
            title: const Text('Emergency blood requests'),
            subtitle: const Text('View active requests matching your profile'),
            trailing: const Icon(Icons.chevron_right),
          ),
        ),
        const SizedBox(height: 20),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            HomeMenuItem(
              icon: Icons.location_on,
              title: 'Find Centre',
              onTap: () => onTabSelected(1),
            ),
            HomeMenuItem(
              icon: Icons.event,
              title: 'Events',
              onTap: () => onTabSelected(2),
            ),
            HomeMenuItem(
              icon: Icons.history,
              title: 'My Donations',
              onTap: () => onTabSelected(3),
            ),
          ],
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value, this.onTap});

  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(label, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeMenuItem extends StatelessWidget {
  const HomeMenuItem({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary, size: 35),
            const SizedBox(height: 8),
            Text(title, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
