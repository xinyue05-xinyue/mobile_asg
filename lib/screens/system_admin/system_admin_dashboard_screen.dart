import 'package:flutter/material.dart';

import '../../data/remote/role_request_repository.dart';
import '../../data/remote/supabase_service.dart';
import '../../models/role_request.dart';
import '../../widgets/notification_button.dart';
import '../login_screen.dart';
import '../statistics_screen.dart';

class SystemAdminDashboardScreen extends StatefulWidget {
  const SystemAdminDashboardScreen({super.key});

  @override
  State<SystemAdminDashboardScreen> createState() =>
      _SystemAdminDashboardScreenState();
}

class _SystemAdminDashboardScreenState
    extends State<SystemAdminDashboardScreen> {
  late Future<List<RoleRequest>> requests;

  @override
  void initState() {
    super.initState();
    requests = loadRequests();
  }

  Future<List<RoleRequest>> loadRequests() {
    final client = SupabaseService.client;
    if (client == null) return Future.value(const []);
    return RoleRequestRepository(client).getPending();
  }

  Future<void> review(RoleRequest request, bool approve) async {
    final client = SupabaseService.client;
    if (client == null) return;
    try {
      await RoleRequestRepository(client).review(
        requestId: request.id,
        approve: approve,
        rejectionReason: approve ? null : 'Application not approved.',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(approve ? 'Access approved.' : 'Application rejected.'),
        ),
      );
      setState(() {
        requests = loadRequests();
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to review application: $error')),
      );
    }
  }

  Future<void> viewProof(RoleRequest request) async {
    final client = SupabaseService.client;
    final proofPath = request.proofPath;
    if (client == null || proofPath == null) return;

    try {
      final url = await RoleRequestRepository(client).createProofUrl(proofPath);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
            child: InteractiveViewer(
              child: Image.network(
                url,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('Unable to display the proof image.'),
                ),
              ),
            ),
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to load proof: $error')));
    }
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
        title: const Text('System Administration'),
        actions: [
          const StatisticsIconButton(),
          const NotificationButton(),
          IconButton(
            onPressed: signOut,
            tooltip: 'Log out',
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: FutureBuilder<List<RoleRequest>>(
        future: requests,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Unable to load applications.'));
          }
          final items = snapshot.data ?? const [];
          if (items.isEmpty) {
            return const Center(child: Text('No pending applications.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final request = items[index];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.requestedRole.label,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(request.organisationName),
                      Text('Position: ${request.staffPosition}'),
                      if (request.reason case final reason?) Text(reason),
                      const SizedBox(height: 8),
                      if (request.proofPath != null)
                        OutlinedButton.icon(
                          onPressed: () => viewProof(request),
                          icon: const Icon(Icons.image_outlined),
                          label: const Text('View proof'),
                        )
                      else
                        const Text('No proof image attached.'),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => review(request, false),
                              child: const Text('Reject'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: () => review(request, true),
                              child: const Text('Approve'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
