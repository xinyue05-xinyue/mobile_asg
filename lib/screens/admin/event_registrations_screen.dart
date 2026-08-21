import 'package:flutter/material.dart';

import '../../data/remote/event_registration_repository.dart';
import '../../data/remote/supabase_service.dart';
import '../../models/donation_event.dart';
import '../../models/event_registration.dart';

class EventRegistrationsScreen extends StatefulWidget {
  const EventRegistrationsScreen({super.key, required this.event});

  final DonationEvent event;

  @override
  State<EventRegistrationsScreen> createState() =>
      _EventRegistrationsScreenState();
}

class _EventRegistrationsScreenState extends State<EventRegistrationsScreen> {
  late Future<List<EventRegistration>> registrations;
  String? verifyingId;

  @override
  void initState() {
    super.initState();
    registrations = loadRegistrations();
  }

  Future<List<EventRegistration>> loadRegistrations() {
    final client = SupabaseService.client;
    if (client == null) return Future.value(const []);
    return EventRegistrationRepository(client).getForEvent(widget.event.id);
  }

  Future<void> verify(EventRegistration registration) async {
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
        title: const Text('Verify event donation?'),
        content: const Text(
          'This records an attended donation and awards 100 points once.',
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
    setState(() => verifyingId = registration.id);
    try {
      await EventRegistrationRepository(client).verifyDonation(
        registrationId: registration.id,
        nextEligibleDate: nextDate,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Attendance verified and 100 points awarded.'),
        ),
      );
      setState(() {
        registrations = loadRegistrations();
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to verify attendance: $error')),
      );
    } finally {
      if (mounted) setState(() => verifyingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.event.title)),
      body: FutureBuilder<List<EventRegistration>>(
        future: registrations,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Unable to load registrations: ${snapshot.error}'),
            );
          }
          final items = snapshot.data ?? const [];
          if (items.isEmpty) {
            return const Center(child: Text('No donor registrations yet.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final registration = items[index];
              return Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    child: Text(registration.bloodType ?? '?'),
                  ),
                  title: Text(registration.donorName),
                  subtitle: Text('Status: ${registration.status}'),
                  trailing: registration.status != 'registered'
                      ? const Icon(Icons.verified, color: Colors.green)
                      : FilledButton(
                          onPressed: verifyingId == null
                              ? () => verify(registration)
                              : null,
                          child: verifyingId == registration.id
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
          );
        },
      ),
    );
  }
}
