import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/remote/event_registration_repository.dart';
import '../../data/remote/supabase_service.dart';

class QrAttendanceScannerScreen extends StatefulWidget {
  const QrAttendanceScannerScreen({super.key, required this.eventId});

  final String eventId;

  @override
  State<QrAttendanceScannerScreen> createState() =>
      _QrAttendanceScannerScreenState();
}

class _QrAttendanceScannerScreenState extends State<QrAttendanceScannerScreen> {
  final controller = MobileScannerController(formats: [BarcodeFormat.qrCode]);
  bool processing = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> detected(BarcodeCapture capture) async {
    if (processing || capture.barcodes.isEmpty) return;
    final value = capture.barcodes.first.rawValue;
    const prefix = 'mydarah:donor:';
    if (value == null || !value.startsWith(prefix)) return;
    final donorId = value.substring(prefix.length);
    if (donorId.isEmpty) return;
    setState(() => processing = true);
    await controller.stop();
    final client = SupabaseService.client;
    if (client == null) return;
    try {
      await EventRegistrationRepository(
        client,
      ).verifyQr(eventId: widget.eventId, donorId: donorId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Attendance verified and 100 points awarded.'),
        ),
      );
      Navigator.pop(context, true);
    } on PostgrestException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
      setState(() => processing = false);
      await controller.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan donor attendance QR')),
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
              color: Colors.black54,
              child: Text(
                processing
                    ? 'Verifying donation…'
                    : 'Ask the donor to open their event attendance QR.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
