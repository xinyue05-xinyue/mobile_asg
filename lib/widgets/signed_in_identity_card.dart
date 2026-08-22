import 'package:flutter/material.dart';

import '../data/remote/supabase_service.dart';

class SignedInIdentityCard extends StatelessWidget {
  const SignedInIdentityCard({super.key, required this.roleLabel});

  final String roleLabel;

  Future<Map<String, Object?>?> _loadProfile() async {
    final client = SupabaseService.client;
    final user = client?.auth.currentUser;
    if (client == null || user == null) return null;
    return client
        .from('profiles')
        .select('full_name')
        .eq('id', user.id)
        .maybeSingle();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, Object?>?>(
      future: _loadProfile(),
      builder: (context, snapshot) {
        final user = SupabaseService.client?.auth.currentUser;
        final name = snapshot.data?['full_name'] as String?;
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              child: Text(
                (name?.trim().isNotEmpty ?? false)
                    ? name!.trim()[0].toUpperCase()
                    : '?',
              ),
            ),
            title: Text(
              snapshot.connectionState != ConnectionState.done
                  ? 'Loading account…'
                  : name ?? 'Signed-in user',
            ),
            subtitle: Text('$roleLabel\n${user?.email ?? ''}'),
            isThreeLine: true,
            trailing: const Icon(Icons.verified_user_outlined),
          ),
        );
      },
    );
  }
}
