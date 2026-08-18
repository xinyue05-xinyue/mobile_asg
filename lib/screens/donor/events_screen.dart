import 'package:flutter/material.dart';

import '../../data/repositories/data_sync_service.dart';
import '../../models/donation_event.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  final syncService = DataSyncService();
  late Future<List<DonationEvent>> events;

  @override
  void initState() {
    super.initState();
    events = syncService.loadEvents();
  }

  String _dateLabel(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$day/$month/${value.year}  $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Donation Events')),
      body: FutureBuilder<List<DonationEvent>>(
        future: events,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Unable to load cached events.'));
          }

          final items = snapshot.data ?? const [];
          if (items.isEmpty) {
            return const Center(child: Text('No cached donation events.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final event = items[index];
              return Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: const Icon(Icons.bloodtype_outlined, size: 34),
                  title: Text(event.title),
                  subtitle: Text(
                    '${event.venue}\n${_dateLabel(event.startsAt)}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
