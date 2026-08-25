import 'package:flutter/material.dart';

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

  Future<void> scanAttendance() async {
    if (!canVerify) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(verificationMessage)));
      return;
    }
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => QrAttendanceScannerScreen(event: widget.event),
      ),
    );
    if (mounted) {
      setState(() => registrations = loadRegistrations());
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.event.title)),
      floatingActionButton: canVerify
          ? FloatingActionButton.extended(
              onPressed: scanAttendance,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Scan donor QR'),
            )
          : null,
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
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
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
                  trailing: registration.status == 'attended'
                      ? const Icon(Icons.verified, color: Colors.green)
                      : const Icon(Icons.qr_code_scanner),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
