import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';
import 'dart:async';

import '../../data/remote/admin_event_repository.dart';
import '../../data/remote/official_centre_repository.dart';
import '../../data/remote/supabase_service.dart';
import '../../models/donation_event.dart';

class EventFormScreen extends StatefulWidget {
  const EventFormScreen({super.key, this.event});

  final DonationEvent? event;

  @override
  State<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends State<EventFormScreen> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController titleController;
  late final TextEditingController venueController;
  late final TextEditingController descriptionController;
  late DateTime startsAt;
  late DateTime endsAt;
  bool isSaving = false;
  LatLng? location;
  Uint8List? imageBytes;
  String? imageExtension;
  String? imageName;
  final mapController = MapController();
  bool searchingLocation = false;
  Timer? venueDebounce;

  @override
  void initState() {
    super.initState();
    final event = widget.event;
    final defaultStart = DateTime.now().add(const Duration(days: 7));
    titleController = TextEditingController(text: event?.title);
    venueController = TextEditingController(text: event?.venue);
    descriptionController = TextEditingController(text: event?.description);
    startsAt = event?.startsAt ?? defaultStart;
    endsAt = event?.endsAt ?? defaultStart.add(const Duration(hours: 5));
    if (event?.latitude != null && event?.longitude != null) {
      location = LatLng(event!.latitude!, event.longitude!);
    }
  }

  Future<void> chooseImage() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp'],
    );
    if (result.isEmpty || !mounted) return;
    final file = result.single;
    final size = await file.length();
    if (!mounted) return;
    if (size > 5 * 1024 * 1024) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event image must be 5 MB or smaller.')),
      );
      return;
    }
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    final extension = file.name.contains('.')
        ? file.name.split('.').last.toLowerCase()
        : 'jpg';
    setState(() {
      imageBytes = bytes;
      imageExtension = extension;
      imageName = file.name;
    });
  }

  String? publicImageUrl(String path) =>
      SupabaseService.client?.storage.from('event-images').getPublicUrl(path);

  @override
  void dispose() {
    titleController.dispose();
    venueController.dispose();
    descriptionController.dispose();
    mapController.dispose();
    venueDebounce?.cancel();
    super.dispose();
  }

  void venueChanged(String value) {
    venueDebounce?.cancel();
    if (value.trim().length < 5) return;
    venueDebounce = Timer(const Duration(milliseconds: 900), findVenue);
  }

  Future<void> findVenue() async {
    final query = venueController.text.trim();
    if (query.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a venue or address first.')),
      );
      return;
    }
    setState(() => searchingLocation = true);
    try {
      final result = await OfficialCentreRepository().searchLocation(query);
      if (!mounted) return;
      final point = LatLng(result.latitude, result.longitude);
      setState(() => location = point);
      mapController.move(point, 16);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to find location: $error')),
      );
    } finally {
      if (mounted) setState(() => searchingLocation = false);
    }
  }

  String dateLabel(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$day/$month/${value.year}  $hour:$minute';
  }

  Future<DateTime?> chooseDateTime(DateTime initial) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (date == null || !mounted) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> save() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    if (!endsAt.isAfter(startsAt)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time.')),
      );
      return;
    }
    if (location == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tap the map to set the event location.')),
      );
      return;
    }
    final client = SupabaseService.client;
    if (client == null) return;
    setState(() => isSaving = true);
    try {
      final repository = AdminEventRepository(client);
      final event = widget.event;
      var imagePath = event?.imagePath;
      if (imageBytes case final bytes?) {
        imagePath = await repository.uploadImage(
          bytes: bytes,
          extension: imageExtension ?? 'jpg',
        );
      }
      if (event == null) {
        await repository.create(
          title: titleController.text.trim(),
          venue: venueController.text.trim(),
          startsAt: startsAt,
          endsAt: endsAt,
          description: descriptionController.text.trim(),
          latitude: location!.latitude,
          longitude: location!.longitude,
          imagePath: imagePath,
        );
      } else {
        await repository.update(
          id: event.id,
          title: titleController.text.trim(),
          venue: venueController.text.trim(),
          startsAt: startsAt,
          endsAt: endsAt,
          description: descriptionController.text.trim(),
          latitude: location!.latitude,
          longitude: location!.longitude,
          imagePath: imagePath,
        );
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } on PostgrestException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.event == null ? 'Create event' : 'Edit event'),
      ),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            TextFormField(
              controller: titleController,
              validator: _required,
              decoration: const InputDecoration(labelText: 'Event title'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: venueController,
              validator: _required,
              onChanged: venueChanged,
              onFieldSubmitted: (_) => findVenue(),
              decoration: const InputDecoration(
                labelText: 'Venue or full address',
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Event location',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            const Text(
              'Enter the venue address above. The map updates automatically; '
              'tap only to adjust the exact entrance or meeting point.',
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (searchingLocation)
                  const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  const Icon(Icons.location_searching, size: 18),
                const SizedBox(width: 8),
                Text(searchingLocation ? 'Locating venue…' : 'Venue location'),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 260,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: FlutterMap(
                  mapController: mapController,
                  options: MapOptions(
                    initialCenter: location ?? const LatLng(3.139, 101.6869),
                    initialZoom: location == null ? 11 : 15,
                    onTap: (_, point) => setState(() => location = point),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.mobile_asg',
                    ),
                    if (location case final point?)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: point,
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
            if (location case final point?)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Selected: ${point.latitude.toStringAsFixed(6)}, '
                  '${point.longitude.toStringAsFixed(6)}',
                ),
              ),
            const SizedBox(height: 16),
            Text(
              'Event image (optional)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (imageBytes case final bytes?)
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.memory(bytes, height: 180, fit: BoxFit.cover),
              )
            else if (widget.event?.imagePath case final path?)
              if (publicImageUrl(path) case final url?)
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.network(url, height: 180, fit: BoxFit.cover),
                ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: chooseImage,
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: Text(imageName ?? 'Choose JPG, PNG or WebP image'),
            ),
            const SizedBox(height: 16),
            _DateTile(
              label: 'Starts',
              value: dateLabel(startsAt),
              onTap: () async {
                final value = await chooseDateTime(startsAt);
                if (value != null) setState(() => startsAt = value);
              },
            ),
            const SizedBox(height: 12),
            _DateTile(
              label: 'Ends',
              value: dateLabel(endsAt),
              onTap: () async {
                final value = await chooseDateTime(endsAt);
                if (value != null) setState(() => endsAt = value);
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: descriptionController,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Description',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: isSaving ? null : save,
              child: isSaving
                  ? const SizedBox.square(
                      dimension: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      widget.event == null ? 'Create event' : 'Save changes',
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String? _required(String? value) {
    return value == null || value.trim().isEmpty ? 'Required field.' : null;
  }
}

class _DateTile extends StatelessWidget {
  const _DateTile({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      tileColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      leading: const Icon(Icons.event_outlined),
      title: Text(label),
      subtitle: Text(value),
      trailing: const Icon(Icons.edit_calendar_outlined),
      onTap: onTap,
    );
  }
}
