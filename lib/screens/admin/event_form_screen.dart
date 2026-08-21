import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/remote/admin_event_repository.dart';
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
  }

  @override
  void dispose() {
    titleController.dispose();
    venueController.dispose();
    descriptionController.dispose();
    super.dispose();
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
    final client = SupabaseService.client;
    if (client == null) return;
    setState(() => isSaving = true);
    try {
      final repository = AdminEventRepository(client);
      final event = widget.event;
      if (event == null) {
        await repository.create(
          title: titleController.text.trim(),
          venue: venueController.text.trim(),
          startsAt: startsAt,
          endsAt: endsAt,
          description: descriptionController.text.trim(),
        );
      } else {
        await repository.update(
          id: event.id,
          title: titleController.text.trim(),
          venue: venueController.text.trim(),
          startsAt: startsAt,
          endsAt: endsAt,
          description: descriptionController.text.trim(),
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
              decoration: const InputDecoration(labelText: 'Venue'),
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
