import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/theme/app_theme.dart';
import '../../data/remote/supabase_service.dart';
import '../../data/remote/system_admin_repository.dart';
import '../../models/donor_level.dart';

class UserDetailScreen extends StatefulWidget {
  const UserDetailScreen({super.key, required this.user});

  final SystemUserSummary user;

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  late Future<SystemUserDetails> details;

  @override
  void initState() {
    super.initState();
    details = loadDetails();
  }

  Future<SystemUserDetails> loadDetails() {
    final client = SupabaseService.client;
    if (client == null) throw StateError('Supabase is not configured.');
    return SystemAdminRepository(client).getUserDetails(widget.user.id);
  }

  String dateLabel(DateTime? value) {
    if (value == null) return 'Not set';
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day/$month/${value.year}';
  }

  String roleLabel(String role) => switch (role) {
    'admin' => 'Organisation admin',
    'hospital' || 'hospital_admin' => 'Hospital',
    'system_admin' => 'System administrator',
    _ => 'Donor',
  };

  Future<void> openDirections(double latitude, double longitude) async {
    final uri = Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': '$latitude,$longitude',
    });
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
        mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open map directions.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.systemAdminBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.systemAdminHeader,
        foregroundColor: Colors.white,
        titleTextStyle: AppTheme.systemAdminHeaderTitleStyle,
        title: const Text('Account details'),
      ),
      body: FutureBuilder<SystemUserDetails>(
        future: details,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Unable to load account details: ${snapshot.error}'),
            );
          }
          final value = snapshot.data!;
          final user = value.summary;
          final isDonor = user.role == 'donor';
          final isHospital =
              user.role == 'hospital' || user.role == 'hospital_admin';
          final organisation = value.organisation;
          final imageUrl = organisation?.imagePath == null
              ? null
              : SupabaseService.client?.storage
                    .from('organisation-images')
                    .getPublicUrl(organisation!.imagePath!);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      if (imageUrl != null) ...[
                        Image.network(
                          imageUrl,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                        const SizedBox(height: 16),
                      ],
                      CircleAvatar(
                        radius: 38,
                        child: Text(user.fullName.trim()[0].toUpperCase()),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        isDonor
                            ? user.fullName
                            : organisation?.displayName ?? user.fullName,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(roleLabel(user.role)),
                      if (isDonor && user.bloodType != null)
                        Text('Blood type ${user.bloodType}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 2,
                children: [
                  if (isDonor) ...[
                    _DetailMetric(
                      label: 'Donations',
                      value: value.donationCount,
                    ),
                    _DetailMetric(
                      label: 'Reward points',
                      value: value.rewardPoints,
                    ),
                    _DetailMetric(
                      label: 'Donor level',
                      textValue: DonorLevel.name(value.donationCount),
                    ),
                  ] else if (isHospital)
                    _DetailMetric(
                      label: 'Emergency requests',
                      value: value.emergencyRequestCount,
                    )
                  else
                    _DetailMetric(
                      label: 'Created events',
                      value: value.eventCount,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      title: Text(isDonor ? 'Phone' : 'Contact phone'),
                      subtitle: Text(
                        isDonor
                            ? value.phone ?? 'Not set'
                            : organisation?.contactPhone ?? 'Not set',
                      ),
                    ),
                    if (isDonor) ...[
                      ListTile(
                        title: const Text('Date of birth'),
                        subtitle: Text(dateLabel(value.dateOfBirth)),
                      ),
                      ListTile(
                        title: const Text('Next eligible donation'),
                        subtitle: Text(dateLabel(value.nextEligibleDate)),
                      ),
                    ] else ...[
                      ListTile(
                        title: const Text('Address'),
                        subtitle: Text(organisation?.address ?? 'Not set'),
                      ),
                      ListTile(
                        title: const Text('Description'),
                        subtitle: Text(organisation?.description ?? 'Not set'),
                      ),
                    ],
                    ListTile(
                      title: const Text('Notifications'),
                      subtitle: Text(
                        value.notificationsEnabled ? 'Enabled' : 'Disabled',
                      ),
                    ),
                    ListTile(
                      title: const Text('Joined'),
                      subtitle: Text(dateLabel(user.createdAt)),
                    ),
                  ],
                ),
              ),
              if (!isDonor &&
                  organisation?.latitude != null &&
                  organisation?.longitude != null) ...[
                const SizedBox(height: 12),
                SizedBox(
                  height: 240,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: FlutterMap(
                      options: MapOptions(
                        initialCenter: LatLng(
                          organisation!.latitude!,
                          organisation.longitude!,
                        ),
                        initialZoom: 15,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.mobile_asg',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: LatLng(
                                organisation.latitude!,
                                organisation.longitude!,
                              ),
                              width: 48,
                              height: 48,
                              child: const Icon(
                                Icons.location_on,
                                size: 46,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                        const RichAttributionWidget(
                          attributions: [
                            TextSourceAttribution('OpenStreetMap contributors'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => openDirections(
                    organisation.latitude!,
                    organisation.longitude!,
                  ),
                  icon: const Icon(Icons.directions_outlined),
                  label: const Text('Open directions'),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _DetailMetric extends StatelessWidget {
  const _DetailMetric({required this.label, this.value, this.textValue});

  final String label;
  final int? value;
  final String? textValue;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              textValue ?? '${value ?? 0}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(label, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
