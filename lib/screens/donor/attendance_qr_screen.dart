import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../app/theme/app_theme.dart';
import '../../models/donation_event.dart';

class DonorAttendanceQrScreen extends StatelessWidget {
  const DonorAttendanceQrScreen({
    super.key,
    required this.event,
    required this.donorId,
  });

  final DonationEvent event;
  final String donorId;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final active = !now.isBefore(event.startsAt) && now.isBefore(event.endsAt);
    return Scaffold(
      backgroundColor: AppTheme.donorBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.donorHeader,
        foregroundColor: Colors.white,
        titleTextStyle: AppTheme.donorHeaderTitleStyle,
        title: const Text('My attendance QR'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        active
                            ? Icons.verified_rounded
                            : Icons.schedule_rounded,
                        color: active ? const Color(0xFF11845B) : Colors.orange,
                        size: 34,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        event.title,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        active ? 'Event in progress' : 'Attendance QR',
                        style: TextStyle(
                          color: active ? const Color(0xFF11845B) : null,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE8DADA)),
                        ),
                        child: QrImageView(
                          data: 'mydarah:event:${event.id}:donor:$donorId',
                          size: 240,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Show this event-specific QR to the authorised collection team only after your donation is completed.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'This QR is for MyDarah attendance verification and is not an official BBISV2 donation record.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF716568),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
