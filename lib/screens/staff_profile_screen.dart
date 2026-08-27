import 'package:flutter/material.dart';
import '../widgets/profile_actions.dart';

import '../data/remote/organisation_profile_repository.dart';
import '../data/remote/supabase_service.dart';
import '../models/organisation_profile.dart';
import 'institution_profile_form_screen.dart';

class StaffProfileScreen extends StatefulWidget {
  const StaffProfileScreen({super.key, required this.roleLabel});
  final String roleLabel;

  @override
  State<StaffProfileScreen> createState() => _StaffProfileScreenState();
}

class _StaffProfileScreenState extends State<StaffProfileScreen> {
  late Future<OrganisationProfile?> profile;

  @override
  void initState() {
    super.initState();
    profile = loadProfile();
  }

  Future<OrganisationProfile?> loadProfile() {
    final client = SupabaseService.client;
    if (client == null) throw StateError('Supabase is not configured.');
    return OrganisationProfileRepository(client).getMine();
  }

  Future<void> refresh() async {
    final refreshed = loadProfile();
    setState(() => profile = refreshed);
    await refreshed;
  }

  Future<void> edit(OrganisationProfile? value) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => InstitutionProfileFormScreen(
          roleLabel: widget.roleLabel,
          profile: value,
        ),
      ),
    );
    if (updated == true && mounted) await refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('${widget.roleLabel} Profile'),
        actions: const [ProfileLogoutButton()],
      ),
      body: FutureBuilder<OrganisationProfile?>(
        future: profile,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('Unable to load profile. Please try again.'),
                const ProfileActions(),
              ],
            );
          }
          final value = snapshot.data;
          final imageUrl = value?.imagePath == null
              ? null
              : SupabaseService.client?.storage
                    .from('organisation-images')
                    .getPublicUrl(value!.imagePath!);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    if (imageUrl != null)
                      Image.network(
                        imageUrl,
                        height: 210,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      )
                    else
                      Container(
                        height: 150,
                        width: double.infinity,
                        color: Theme.of(context).colorScheme.primaryContainer,
                        child: const Icon(Icons.business_outlined, size: 64),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Text(
                            value?.displayName ?? 'Complete your profile',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(widget.roleLabel),
                          if (value?.description case final description?) ...[
                            const SizedBox(height: 10),
                            Text(description, textAlign: TextAlign.center),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.phone_outlined),
                      title: const Text('Contact phone'),
                      subtitle: Text(value?.contactPhone ?? 'Not set'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.location_on_outlined),
                      title: const Text('Address'),
                      subtitle: Text(value?.address ?? 'Not set'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => edit(value),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit institutional profile'),
              ),
              const SizedBox(height: 24),
              const ProfileActions(),
            ],
          );
        },
      ),
    );
  }
}
