import 'package:flutter/material.dart';

import '../../data/remote/emergency_repository.dart';
import '../../data/remote/supabase_service.dart';
import '../../models/emergency_request.dart';
import '../../widgets/notification_button.dart';
import '../login_screen.dart';
import 'create_emergency_screen.dart';
import 'emergency_responses_screen.dart';

class HospitalDashboardScreen extends StatefulWidget {
  const HospitalDashboardScreen({super.key});

  @override
  State<HospitalDashboardScreen> createState() =>
      _HospitalDashboardScreenState();
}

class _HospitalDashboardScreenState extends State<HospitalDashboardScreen> {
  late Future<List<EmergencyRequest>> requests;

  @override
  void initState() {
    super.initState();
    requests = loadRequests();
  }

  Future<List<EmergencyRequest>> loadRequests() {
    final client = SupabaseService.client;
    if (client == null) return Future.value(const []);
    return EmergencyRepository(client).getHospitalRequests();
  }

  String dateLabel(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$day/$month/${value.year}  $hour:$minute';
  }

  Future<void> createRequest() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const CreateEmergencyScreen()),
    );
    if (created == true) {
      setState(() {
        requests = loadRequests();
      });
    }
  }

  Future<void> updateStatus(EmergencyRequest request, String status) async {
    final client = SupabaseService.client;
    if (client == null) return;
    try {
      await EmergencyRepository(client).updateStatus(request.id, status);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Request marked as $status.')));
      setState(() {
        requests = loadRequests();
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to update request: $error')),
      );
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
        title: const Text('Hospital Portal'),
        actions: [
          const NotificationButton(),
          IconButton(onPressed: signOut, icon: const Icon(Icons.logout)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: createRequest,
        icon: const Icon(Icons.add_alert_outlined),
        label: const Text('New request'),
      ),
      body: FutureBuilder<List<EmergencyRequest>>(
        future: requests,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Unable to load requests: ${snapshot.error}'),
            );
          }
          final items = snapshot.data ?? const [];
          final activeCount = items
              .where((item) => item.status == 'active')
              .length;
          return RefreshIndicator(
            onRefresh: () async => setState(() {
              requests = loadRequests();
            }),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: [
                Text(
                  'Emergency Dashboard',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: const Icon(Icons.emergency_outlined),
                    title: Text('$activeCount active requests'),
                    subtitle: Text('${items.length} total requests'),
                  ),
                ),
                const SizedBox(height: 20),
                if (items.isEmpty)
                  const Card(
                    child: ListTile(title: Text('No emergency requests yet.')),
                  )
                else
                  ...items.map(
                    (request) => Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(child: Text(request.bloodType)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${request.unitsNeeded} units needed',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleMedium,
                                      ),
                                      Text(
                                        '${request.urgency.toUpperCase()} • ${request.status.toUpperCase()}',
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text('Deadline: ${dateLabel(request.deadline)}'),
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => EmergencyResponsesScreen(
                                    request: request,
                                  ),
                                ),
                              ),
                              icon: const Icon(Icons.people_outline),
                              label: const Text('View donor responses'),
                            ),
                            if (request.status == 'active') ...[
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () =>
                                          updateStatus(request, 'cancelled'),
                                      child: const Text('Cancel'),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: FilledButton(
                                      onPressed: () =>
                                          updateStatus(request, 'fulfilled'),
                                      child: const Text('Fulfilled'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
