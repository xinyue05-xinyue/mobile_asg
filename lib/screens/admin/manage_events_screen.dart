import 'package:flutter/material.dart';

import '../../data/remote/admin_event_repository.dart';
import '../../data/remote/supabase_service.dart';
import '../../models/donation_event.dart';
import 'event_form_screen.dart';
import 'event_registrations_screen.dart';

class ManageEventsScreen extends StatefulWidget {
  const ManageEventsScreen({super.key});

  @override
  State<ManageEventsScreen> createState() => _ManageEventsScreenState();
}

class _ManageEventsScreenState extends State<ManageEventsScreen> {
  late Future<List<DonationEvent>> events;

  @override
  void initState() {
    super.initState();
    events = loadEvents();
  }

  Future<List<DonationEvent>> loadEvents() {
    final client = SupabaseService.client;
    if (client == null) return Future.value(const []);
    return AdminEventRepository(client).getOwnEvents();
  }

  String dateLabel(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day/$month/${value.year}';
  }

  Future<void> openForm([DonationEvent? event]) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => EventFormScreen(event: event)),
    );
    if (changed == true) {
      setState(() {
        events = loadEvents();
      });
    }
  }

  Future<void> cancel(DonationEvent event) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel this event?'),
        content: const Text('The event remains in the audit history.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Back'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancel event'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final client = SupabaseService.client;
    if (client == null) return;
    await AdminEventRepository(client).cancel(event.id);
    if (mounted) {
      setState(() {
        events = loadEvents();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Events')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: openForm,
        icon: const Icon(Icons.add),
        label: const Text('Create event'),
      ),
      body: FutureBuilder<List<DonationEvent>>(
        future: events,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Unable to load events: ${snapshot.error}'),
            );
          }
          final items = snapshot.data ?? const [];
          if (items.isEmpty) {
            return const Center(child: Text('No events created yet.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final event = items[index];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text('${event.venue} • ${dateLabel(event.startsAt)}'),
                      Text('Status: ${event.status}'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          OutlinedButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    EventRegistrationsScreen(event: event),
                              ),
                            ),
                            child: const Text('Registrations'),
                          ),
                          if (event.status == 'upcoming') ...[
                            OutlinedButton(
                              onPressed: () => openForm(event),
                              child: const Text('Edit'),
                            ),
                            TextButton(
                              onPressed: () => cancel(event),
                              child: const Text('Cancel'),
                            ),
                          ],
                        ],
                      ),
                    ],
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
