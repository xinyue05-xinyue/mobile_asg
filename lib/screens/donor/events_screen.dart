import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

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
  final searchController = TextEditingController();
  late Future<_EventData> data;
  String? registeringEventId;
  bool registeredExpanded = false;

  @override
  void initState() {
    super.initState();
    data = loadData();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<_EventData> loadData() async {
    final events = await syncService.loadEvents();
    final client = SupabaseService.client;
    final registrationStatuses = client == null
        ? <String, String>{}
        : await EventRegistrationRepository(client).getMyRegistrationStatuses();
    final now = DateTime.now();
    final visibleEvents = events.where((event) {
      if (event.status != 'upcoming') return false;
      if (event.startsAt.isAfter(now)) return true;

      // Keep a registered event accessible while it is running and for one
      // day afterwards, so the donor can show the attendance QR after giving
      // blood. Past events are never offered for new registration.
      final registrationStatus = registrationStatuses[event.id];
      return registrationStatus == 'registered' &&
          event.endsAt.add(const Duration(days: 1)).isAfter(now);
    }).toList();
    return _EventData(visibleEvents, registrationStatuses);
  }

  String dateLabel(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$day/$month/${value.year}  $hour:$minute';
  }

  String timeLabel(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  bool matchesSearch(DonationEvent event) {
    final query = searchController.text.trim().toLowerCase();
    return query.isEmpty ||
        event.title.toLowerCase().contains(query) ||
        event.venue.toLowerCase().contains(query) ||
        (event.description?.toLowerCase().contains(query) ?? false);
  }

  Future<void> showEventDetails(
    DonationEvent event, {
    required String? registrationStatus,
  }) async {
    final qrEventId = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.bloodtype_outlined, size: 36),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      event.title,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                ],
              ),
              if (event.imagePath case final path?) ...[
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    SupabaseService.client!.storage
                        .from('event-images')
                        .getPublicUrl(path),
                    height: 210,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.location_on_outlined),
                title: const Text('Venue'),
                subtitle: Text(event.venue),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_month_outlined),
                title: const Text('Date and time'),
                subtitle: Text(
                  '${dateLabel(event.startsAt)} – ${timeLabel(event.endsAt)}',
                ),
              ),
              if (event.description case final description?) ...[
                const SizedBox(height: 8),
                Text(
                  'About this event',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(description),
              ],
              if (event.latitude != null && event.longitude != null) ...[
                const SizedBox(height: 18),
                Text(
                  'Event location',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 220,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: FlutterMap(
                      options: MapOptions(
                        initialCenter: LatLng(
                          event.latitude!,
                          event.longitude!,
                        ),
                        initialZoom: 15,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.mobile_asg',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: LatLng(event.latitude!, event.longitude!),
                              width: 48,
                              height: 48,
                              child: const Icon(
                                Icons.location_on,
                                size: 46,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                        const RichAttributionWidget(
                          attributions: [
                            TextSourceAttribution('OpenStreetMap contributors'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => openDirections(event),
                    icon: const Icon(Icons.directions_outlined),
                    label: const Text('Open directions'),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed:
                      registrationStatus != null || registeringEventId != null
                      ? null
                      : () {
                          Navigator.pop(sheetContext);
                          confirmRegistration(event);
                        },
                  icon: Icon(
                    registrationStatus != null
                        ? Icons.check
                        : Icons.event_available,
                  ),
                  label: Text(
                    registrationStatus == 'attended'
                        ? 'Attendance verified'
                        : registrationStatus != null
                        ? 'Already registered'
                        : 'Register',
                  ),
                ),
              ),
              if (registrationStatus == 'registered') ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: event.startsAt.isAfter(DateTime.now())
                        ? null
                        : () => Navigator.pop(sheetContext, event.id),
                    icon: const Icon(Icons.qr_code),
                    label: Text(
                      event.startsAt.isAfter(DateTime.now())
                          ? 'QR available when event starts'
                          : 'Show attendance QR',
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
    if (qrEventId != null && mounted) {
      await showAttendanceQr(qrEventId);
    }
  }

  Future<void> showAttendanceQr(String eventId) async {
    final userId = SupabaseService.client?.auth.currentUser?.id;
    if (userId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in again to show your QR.')),
      );
      return;
    }
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => _AttendanceQrScreen(
          qrData: 'mydarah:event:$eventId:donor:$userId',
        ),
      ),
    );
  }

  Future<void> openDirections(DonationEvent event) async {
    final latitude = event.latitude;
    final longitude = event.longitude;
    if (latitude == null || longitude == null) return;
    final uri = Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': '$latitude,$longitude',
    });
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
        mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open map directions.')),
      );
    }
  }

  Future<void> confirmRegistration(DonationEvent event) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm registration'),
        content: Text(
          'Register for ${event.title} at ${event.venue} on '
          '${dateLabel(event.startsAt)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Register'),
          ),
        ],
      ),
    );
    if (confirmed == true) await register(event);
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

  Widget eventCard(DonationEvent event, {required String? registrationStatus}) {
    final registered = registrationStatus != null;
    return Card(
      clipBehavior: Clip.antiAlias,
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
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 18),
                const SizedBox(width: 6),
                Expanded(child: Text(event.venue)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.schedule, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${dateLabel(event.startsAt)} – ${timeLabel(event.endsAt)}',
                  ),
                ),
              ],
            ),
            if (event.description case final description?) ...[
              const SizedBox(height: 8),
              Text(description),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                TextButton(
                  onPressed: () => showEventDetails(
                    event,
                    registrationStatus: registrationStatus,
                  ),
                  child: const Text('View details'),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: registered || registeringEventId != null
                      ? null
                      : () => confirmRegistration(event),
                  icon: registeringEventId == event.id
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(registered ? Icons.check : Icons.event_available),
                  label: Text(
                    registrationStatus == 'attended'
                        ? 'Attended'
                        : registered
                        ? 'Registered'
                        : 'Register',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Donation Events'),
      ),
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
          final matching = value.events.where(matchesSearch).toList();
          final registered = matching
              .where(
                (event) => value.registrationStatuses.containsKey(event.id),
              )
              .toList();
          final available = matching
              .where(
                (event) => !value.registrationStatuses.containsKey(event.id),
              )
              .toList();
          return RefreshIndicator(
            onRefresh: () async => setState(() {
              data = loadData();
            }),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextField(
                  controller: searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search event or venue',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: searchController.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear search',
                            onPressed: () {
                              searchController.clear();
                              setState(() {});
                            },
                            icon: const Icon(Icons.clear),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: ExpansionTile(
                    initiallyExpanded: registeredExpanded,
                    onExpansionChanged: (expanded) =>
                        setState(() => registeredExpanded = expanded),
                    leading: const Icon(Icons.how_to_reg),
                    title: const Text('My registered events'),
                    subtitle: Text(
                      '${registered.length} event${registered.length == 1 ? '' : 's'}',
                    ),
                    childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    children: registered.isEmpty
                        ? const [
                            Padding(
                              padding: EdgeInsets.all(16),
                              child: Text('No registered events.'),
                            ),
                          ]
                        : [
                            for (final event in registered) ...[
                              eventCard(
                                event,
                                registrationStatus:
                                    value.registrationStatuses[event.id],
                              ),
                              const SizedBox(height: 8),
                            ],
                          ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Text(
                      'Available events',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Spacer(),
                    Text('${available.length}'),
                  ],
                ),
                const SizedBox(height: 12),
                if (available.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 48),
                    child: Center(
                      child: Text(
                        value.events.isEmpty
                            ? 'No upcoming donation events.'
                            : 'No available events match your search.',
                      ),
                    ),
                  )
                else
                  for (final event in available) ...[
                    eventCard(event, registrationStatus: null),
                    const SizedBox(height: 12),
                  ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _EventData {
  const _EventData(this.events, this.registrationStatuses);

  final List<DonationEvent> events;
  final Map<String, String> registrationStatuses;
}

class _AttendanceQrScreen extends StatelessWidget {
  const _AttendanceQrScreen({required this.qrData});

  final String qrData;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My attendance QR')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: QrImageView(data: qrData, size: 240),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Show this QR to the organisation admin only after you donate.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
