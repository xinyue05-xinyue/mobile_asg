import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/remote/event_registration_repository.dart';
import '../../data/remote/supabase_service.dart';
import '../../models/donation_event.dart';
import '../../models/event_registration.dart';

class QrAttendanceScannerScreen extends StatefulWidget {
  const QrAttendanceScannerScreen({super.key, required this.event});

  final DonationEvent event;

  @override
  State<QrAttendanceScannerScreen> createState() =>
      _QrAttendanceScannerScreenState();
}

class _QrAttendanceScannerScreenState extends State<QrAttendanceScannerScreen> {
  final controller = MobileScannerController(formats: [BarcodeFormat.qrCode]);
  bool processing = false;
  int verifiedCount = 0;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  String dateLabel(DateTime? date) {
    if (date == null) return 'Eligible now';
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  Future<bool> confirmDonor(EventRegistration registration) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Confirm completed donation'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 34,
                    child: Text(registration.bloodType ?? '?'),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    registration.donorName,
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.bloodtype_outlined),
                    title: const Text('Blood type'),
                    subtitle: Text(registration.bloodType ?? 'Not set'),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.phone_outlined),
                    title: const Text('Contact phone'),
                    subtitle: Text(registration.phone ?? 'Not set'),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.event_available_outlined),
                    title: const Text('Eligibility'),
                    subtitle: Text(dateLabel(registration.nextEligibleDate)),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton.icon(
                onPressed: () => Navigator.pop(dialogContext, true),
                icon: const Icon(Icons.verified_outlined),
                label: const Text('Confirm donation'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> detected(BarcodeCapture capture) async {
    if (processing || capture.barcodes.isEmpty) return;
    final value = capture.barcodes.first.rawValue;
    final prefix = 'mydarah:event:${widget.event.id}:donor:';
    if (value == null || !value.startsWith(prefix)) {
      setState(() => processing = true);
      await controller.stop();
      await showError('This QR does not belong to ${widget.event.title}.');
      return resumeScanning();
    }

    final donorId = value.substring(prefix.length).trim();
    if (donorId.isEmpty) return;
    setState(() => processing = true);
    await controller.stop();

    final client = SupabaseService.client;
    if (client == null) {
      await showError('Supabase is not configured.');
      return resumeScanning();
    }

    try {
      final repository = EventRegistrationRepository(client);
      final registration = await repository.getForEventAndDonor(
        eventId: widget.event.id,
        donorId: donorId,
      );
      if (registration == null) {
        await showError('This donor is not registered for this event.');
      } else if (registration.status == 'attended') {
        await showError('${registration.donorName} is already verified.');
      } else if (registration.status != 'registered') {
        await showError('This registration is ${registration.status}.');
      } else if (await confirmDonor(registration)) {
        await repository.verifyQr(eventId: widget.event.id, donorId: donorId);
        verifiedCount++;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${registration.donorName} verified. 100 points awarded and eligibility set three months later.',
              ),
            ),
          );
        }
      }
    } on PostgrestException catch (error) {
      await showError(error.message);
    } catch (error) {
      await showError('Unable to verify QR: $error');
    }
    await resumeScanning();
  }

  Future<void> showError(String message) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('QR not verified'),
        content: Text(message),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Scan again'),
          ),
        ],
      ),
    );
  }

  Future<void> resumeScanning() async {
    if (!mounted) return;
    setState(() => processing = false);
    await controller.start();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan donor QR'),
        leading: IconButton(
          onPressed: () => Navigator.pop(context, verifiedCount > 0),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(controller: controller, onDetect: detected),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 4),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              color: Colors.black87,
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      processing
                          ? 'Checking donor…'
                          : 'Scan each donor after the blood donation is completed.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$verifiedCount verified in this session',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
