import 'package:flutter/material.dart';

import '../../data/remote/profile_repository.dart';
import '../../data/remote/supabase_service.dart';
import '../../models/donor_profile.dart';

class SystemAdminProfileScreen extends StatefulWidget {
  const SystemAdminProfileScreen({super.key});

  @override
  State<SystemAdminProfileScreen> createState() =>
      _SystemAdminProfileScreenState();
}

class _SystemAdminProfileScreenState extends State<SystemAdminProfileScreen> {
  late Future<DonorProfile> profile;

  @override
  void initState() {
    super.initState();
    profile = loadProfile();
  }

  Future<DonorProfile> loadProfile() {
    final client = SupabaseService.client;
    if (client == null) throw StateError('Supabase is not configured.');
    return ProfileRepository(client).getCurrentProfile();
  }

  Future<void> edit(DonorProfile current) async {
    final name = TextEditingController(text: current.fullName);
    final phone = TextEditingController(text: current.phone ?? '');
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit administrator profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Full name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Contact phone'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (name.text.trim().isNotEmpty) {
                Navigator.pop(dialogContext, true);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (saved == true) {
      final client = SupabaseService.client!;
      await ProfileRepository(
        client,
      ).updateBasicProfile(fullName: name.text.trim(), phone: phone.text);
      if (mounted) setState(() => profile = loadProfile());
    }
    name.dispose();
    phone.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final email = SupabaseService.client?.auth.currentUser?.email ?? 'Not set';
    return Scaffold(
      appBar: AppBar(title: const Text('Administrator profile')),
      body: FutureBuilder<DonorProfile>(
        future: profile,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Unable to load profile: ${snapshot.error}'),
            );
          }
          final value = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const CircleAvatar(
                        radius: 42,
                        child: Icon(Icons.admin_panel_settings, size: 42),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        value.fullName,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const Text('System administrator'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.email_outlined),
                      title: const Text('Email'),
                      subtitle: Text(email),
                    ),
                    ListTile(
                      leading: const Icon(Icons.phone_outlined),
                      title: const Text('Contact phone'),
                      subtitle: Text(value.phone ?? 'Not set'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => edit(value),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit profile'),
              ),
            ],
          );
        },
      ),
    );
  }
}
