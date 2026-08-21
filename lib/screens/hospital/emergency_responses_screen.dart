import 'package:flutter/material.dart';

import '../../data/remote/emergency_response_repository.dart';
import '../../data/remote/supabase_service.dart';
import '../../models/emergency_request.dart';
import '../../models/emergency_response.dart';

class EmergencyResponsesScreen extends StatefulWidget {
  const EmergencyResponsesScreen({super.key, required this.request});

  final EmergencyRequest request;

  @override
  State<EmergencyResponsesScreen> createState() =>
      _EmergencyResponsesScreenState();
}

class _EmergencyResponsesScreenState extends State<EmergencyResponsesScreen> {
  late Future<List<EmergencyResponse>> responses;
  String? verifyingResponseId;

  @override
  void initState() {
    super.initState();
    responses = loadResponses();
  }

  Future<List<EmergencyResponse>> loadResponses() {
    final client = SupabaseService.client;
    if (client == null) return Future.value(const []);
    return EmergencyResponseRepository(client).getForRequest(widget.request.id);
  }

  Future<void> verify(EmergencyResponse response) async {
    final today = DateTime.now();
    final nextDate = await showDatePicker(
      context: context,
      initialDate: today.add(const Duration(days: 60)),
      firstDate: today.add(const Duration(days: 1)),
      lastDate: today.add(const Duration(days: 365)),
      helpText: 'Set next eligible donation date',
    );
    if (nextDate == null || !mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Verify completed donation?'),
        content: const Text(
          'This creates a verified donation record and awards 100 points. This action cannot be repeated.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Back'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Verify'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final client = SupabaseService.client;
    if (client == null) return;
    setState(() => verifyingResponseId = response.id);
    try {
      await EmergencyResponseRepository(
        client,
      ).verifyDonation(responseId: response.id, nextEligibleDate: nextDate);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Donation verified and 100 points awarded.'),
        ),
      );
      setState(() {
        responses = loadResponses();
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to verify donation: $error')),
      );
    } finally {
      if (mounted) setState(() => verifyingResponseId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Donor responses')),
      body: FutureBuilder<List<EmergencyResponse>>(
        future: responses,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Unable to load responses: ${snapshot.error}'),
            );
          }
          final items = snapshot.data ?? const [];
          if (items.isEmpty) {
            return const Center(child: Text('No donor responses yet.'));
          }
          return RefreshIndicator(
            onRefresh: () async => setState(() {
              responses = loadResponses();
            }),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final response = items[index];
                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      child: Text(response.bloodType ?? '?'),
                    ),
                    title: Text(response.donorName),
                    subtitle: Text('Status: ${response.status}'),
                    trailing: response.status != 'pending'
                        ? const Icon(Icons.verified, color: Colors.green)
                        : FilledButton(
                            onPressed: verifyingResponseId == null
                                ? () => verify(response)
                                : null,
                            child: verifyingResponseId == response.id
                                ? const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Verify'),
                          ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
