import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/remote/event_registration_repository.dart';
import '../../data/remote/supabase_service.dart';
import '../../data/repositories/data_sync_service.dart';
import '../../models/donation_event.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  final syncService = DataSyncService();
  late Future<_EventData> data;
  String? registeringEventId;

  @override
  void initState() {
    super.initState();
    data = loadData();
  }

  Future<_EventData> loadData() async {
    final events = await syncService.loadEvents();
    final upcoming = events
        .where(
          (event) =>
              event.status == 'upcoming' &&
              event.startsAt.isAfter(DateTime.now()),
        )
        .toList();
    final client = SupabaseService.client;
    final registeredIds = client == null
        ? <String>{}
        : await EventRegistrationRepository(client).getMyRegisteredEventIds();
    return _EventData(upcoming, registeredIds);
  }

  String dateLabel(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$day/$month/${value.year}  $hour:$minute';
  }

  Future<void> register(DonationEvent event) async {
    final client = SupabaseService.client;
    if (client == null) return;
    setState(() => registeringEventId = event.id);
    try {
      await EventRegistrationRepository(client).register(event.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event registration completed.')),
      );
      setState(() {
        data = loadData();
      });
    } on PostgrestException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => registeringEventId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Donation Events')),
      body: FutureBuilder<_EventData>(
        future: data,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Unable to load events: ${snapshot.error}'),
            );
          }
          final value = snapshot.data ?? const _EventData([], {});
          if (value.events.isEmpty) {
            return const Center(child: Text('No upcoming donation events.'));
          }
          return RefreshIndicator(
            onRefresh: () async => setState(() {
              data = loadData();
            }),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: value.events.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final event = value.events[index];
                final registered = value.registeredIds.contains(event.id);
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.bloodtype_outlined, size: 34),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                event.title,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(event.venue),
                        Text(dateLabel(event.startsAt)),
                        if (event.description case final description?) ...[
                          const SizedBox(height: 8),
                          Text(description),
                        ],
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: registered || registeringEventId != null
                              ? null
                              : () => register(event),
                          icon: Icon(
                            registered ? Icons.check : Icons.event_available,
                          ),
                          label: Text(
                            registered ? 'Registered' : 'Register for event',
                          ),
                        ),
                      ],
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

class _EventData {
  const _EventData(this.events, this.registeredIds);

  final List<DonationEvent> events;
  final Set<String> registeredIds;
}
