import 'package:flutter/material.dart';

import '../../data/remote/profile_repository.dart';
import '../../data/remote/role_request_repository.dart';
import '../../data/remote/supabase_service.dart';
import '../../models/profile_overview.dart';
import '../../models/role_request.dart';
import '../login_screen.dart';
import 'edit_profile_screen.dart';
import 'role_application_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Future<ProfileOverview>? overview;
  Future<List<RoleRequest>>? requests;

  @override
  void initState() {
    super.initState();
    refresh();
  }

  void refresh() {
    final client = SupabaseService.client;
    overview = client == null ? null : ProfileRepository(client).getOverview();
    requests = client == null
        ? Future.value(const [])
        : RoleRequestRepository(client).getMine();
  }

  String dateLabel(DateTime? value) {
    if (value == null) return 'Not available';
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day/$month/${value.year}';
  }

  String rewardLevel(int points) {
    if (points >= 1000) return 'Gold Donor';
    if (points >= 500) return 'Silver Donor';
    if (points >= 100) return 'Bronze Donor';
    return 'New Donor';
  }

  Future<void> editProfile(ProfileOverview value) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(profile: value.profile),
      ),
    );
    if (updated == true) setState(refresh);
  }

  Future<void> openApplication() async {
    final submitted = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const RoleApplicationScreen()),
    );
    if (submitted == true) setState(refresh);
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
        title: const Text('My Profile'),
        actions: [
          IconButton(
            onPressed: signOut,
            tooltip: 'Log out',
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: overview == null
          ? const Center(child: Text('Profile requires a Supabase login.'))
          : FutureBuilder<ProfileOverview>(
              future: overview,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text('Unable to load profile: ${snapshot.error}'),
                    ),
                  );
                }
                final value = snapshot.data!;
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 32,
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primaryContainer,
                              child: const Icon(Icons.person, size: 34),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    value.profile.fullName,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleLarge,
                                  ),
                                  Text(
                                    SupabaseService
                                            .client
                                            ?.auth
                                            .currentUser
                                            ?.email ??
                                        '',
                                  ),
                                  Text(
                                    'Blood type: ${value.profile.bloodType ?? 'Not set'}',
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => editProfile(value),
                              tooltip: 'Edit profile',
                              icon: const Icon(Icons.edit_outlined),
                            ),
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
                            value: '${value.donations.length}',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _MetricCard(
                            label: 'Points',
                            value: '${value.rewardPoints}',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _MetricCard(
                            label: 'Next eligible',
                            value: value.profile.nextEligibleDate == null
                                ? 'Not set'
                                : dateLabel(value.profile.nextEligibleDate),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.emoji_events_outlined),
                        title: Text(rewardLevel(value.rewardPoints)),
                        subtitle: const Text(
                          'Verified emergency donations earn 100 points.',
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Personal information',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Card(
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.phone_outlined),
                            title: const Text('Phone'),
                            subtitle: Text(value.profile.phone ?? 'Not set'),
                          ),
                          ListTile(
                            leading: const Icon(Icons.cake_outlined),
                            title: const Text('Date of birth'),
                            subtitle: Text(
                              dateLabel(value.profile.dateOfBirth),
                            ),
                          ),
                          ListTile(
                            leading: const Icon(Icons.notifications_outlined),
                            title: const Text('Notifications'),
                            subtitle: Text(
                              value.profile.notificationsEnabled
                                  ? 'Enabled'
                                  : 'Disabled',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Donation history',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    if (value.donations.isEmpty)
                      const Card(
                        child: ListTile(
                          title: Text('No donation records yet.'),
                        ),
                      )
                    else
                      ...value.donations.map(
                        (donation) => Card(
                          child: ListTile(
                            leading: const Icon(Icons.bloodtype_outlined),
                            title: Text(dateLabel(donation.donationDate)),
                            subtitle: Text(donation.verificationStatus),
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),
                    Text(
                      'Reward history',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    if (value.rewards.isEmpty)
                      const Card(
                        child: ListTile(
                          title: Text('No reward transactions yet.'),
                        ),
                      )
                    else
                      ...value.rewards.map(
                        (reward) => Card(
                          child: ListTile(
                            leading: const Icon(Icons.stars_outlined),
                            title: Text(
                              '${reward.points > 0 ? '+' : ''}${reward.points} points',
                            ),
                            subtitle: Text(
                              '${reward.transactionType} • ${dateLabel(reward.createdAt)}',
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),
                    Text(
                      'Staff access',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: openApplication,
                      icon: const Icon(Icons.badge_outlined),
                      label: const Text('Apply for admin or hospital access'),
                    ),
                    const SizedBox(height: 8),
                    _RoleRequests(requestFuture: requests),
                  ],
                );
              },
            ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(
              value,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(label, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _RoleRequests extends StatelessWidget {
  const _RoleRequests({required this.requestFuture});

  final Future<List<RoleRequest>>? requestFuture;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<RoleRequest>>(
      future: requestFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = snapshot.data ?? const [];
        if (items.isEmpty) return const Text('No access applications.');
        return Column(
          children: items
              .map(
                (request) => Card(
                  child: ListTile(
                    title: Text(request.requestedRole.label),
                    subtitle: Text(request.organisationName),
                    trailing: Text(request.status.toUpperCase()),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}
