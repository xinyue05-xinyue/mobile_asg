import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/remote/event_registration_repository.dart';
import '../../data/remote/supabase_service.dart';
import '../../models/donation_event.dart';
import '../../models/event_registration.dart';
import 'qr_attendance_scanner_screen.dart';

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
    if (!canVerify) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(verificationMessage)));
      return;
    }
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
    } on PostgrestException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_friendlyVerificationError(error.message))),
      );
    } finally {
      if (mounted) setState(() => verifyingId = null);
    }
  }

  bool get canVerify =>
      widget.event.status != 'cancelled' &&
      !widget.event.startsAt.isAfter(DateTime.now());

  String get verificationMessage {
    if (widget.event.status == 'cancelled') {
      return 'Attendance cannot be verified for a cancelled event.';
    }
    return 'Attendance can only be verified after the event starts.';
  }

  String _friendlyVerificationError(String message) {
    if (message.contains('not available for attendance')) {
      return verificationMessage;
    }
    if (message.contains('not currently eligible')) {
      return 'This donor is not currently eligible to donate.';
    }
    if (message.contains('Active registration not found')) {
      return 'This registration has already been processed.';
    }
    return 'Unable to verify attendance. Please try again.';
  }

  Future<void> scanAttendance() async {
    if (!canVerify) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(verificationMessage)));
      return;
    }
    final verified = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => QrAttendanceScannerScreen(eventId: widget.event.id),
      ),
    );
    if (verified == true && mounted) {
      setState(() => registrations = loadRegistrations());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.event.title),
        actions: [
          IconButton(
            onPressed: canVerify ? scanAttendance : null,
            tooltip: 'Scan attendance QR',
            icon: const Icon(Icons.qr_code_scanner),
          ),
        ],
      ),
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
            itemCount: items.length + (canVerify ? 0 : 1),
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              if (!canVerify && index == 0) {
                return Card(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  child: ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: Text(verificationMessage),
                    subtitle: Text(
                      'Event starts: ${widget.event.startsAt.toString().substring(0, 16)}',
                    ),
                  ),
                );
              }
              final registration = items[index - (canVerify ? 0 : 1)];
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
                          onPressed: canVerify && verifyingId == null
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
