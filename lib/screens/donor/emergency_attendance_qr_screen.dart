import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../models/emergency_attendance_qr.dart';
import '../../models/emergency_request.dart';

class EmergencyAttendanceQrScreen extends StatelessWidget {
  const EmergencyAttendanceQrScreen({
    super.key,
    required this.request,
    required this.donorId,
  });

  final EmergencyRequest request;
  final String donorId;

  @override
  Widget build(BuildContext context) {
    final payload = EmergencyAttendanceQr(
      requestId: request.id,
      donorId: donorId,
    ).value;
    return Scaffold(
      appBar: AppBar(title: const Text('Emergency donation QR')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    'Hospital emergency request',
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text('${request.bloodType} emergency donation'),
                  const SizedBox(height: 24),
                  Semantics(
                    label: 'Emergency donation attendance QR code',
                    child: QrImageView(data: payload, size: 240),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Show this QR to hospital staff only after the blood donation is completed.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Card(
            child: ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('MyDarah verification'),
              subtitle: Text(
                'Scanning awards app points and updates app eligibility. It is not an official Ministry of Health donor record.',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
