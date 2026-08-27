import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/remote/feedback_repository.dart';
import '../data/remote/supabase_service.dart';
import '../models/user_feedback.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final message = TextEditingController();
  String category = 'general';
  bool submitting = false;
  List<FeedbackAttachment> attachments = [];
  late Future<List<UserFeedback>> feedback;

  @override
  void initState() {
    super.initState();
    feedback = load();
  }

  @override
  void dispose() {
    message.dispose();
    super.dispose();
  }

  Future<List<UserFeedback>> load() {
    final client = SupabaseService.client;
    if (client == null) return Future.value(const []);
    return FeedbackRepository(client).getMine();
  }

  Future<void> submit() async {
    final text = message.text.trim();
    if (text.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter at least 10 characters.')),
      );
      return;
    }
    setState(() => submitting = true);
    try {
      await FeedbackRepository(
        SupabaseService.client!,
      ).create(category: category, message: text, attachments: attachments);
      message.clear();
      if (!mounted) return;
      setState(() {
        attachments = [];
        feedback = load();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Feedback sent to the system admin.')),
      );
    } on PostgrestException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } on StorageException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } on FormatException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } on ArgumentError catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message?.toString() ?? 'Invalid file.')),
        );
      }
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  Future<void> pickAttachments() async {
    final remaining = 5 - attachments.length;
    if (remaining == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You already selected 5 attachments.')),
      );
      return;
    }
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const [
        'pdf',
        'jpg',
        'jpeg',
        'png',
        'webp',
        'doc',
        'docx',
      ],
    );
    if (files.isEmpty || !mounted) return;
    final added = <FeedbackAttachment>[];
    for (final file in files.take(remaining)) {
      final bytes = await file.readAsBytes();
      if (bytes.lengthInBytes > 5 * 1024 * 1024) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Each attachment must be 5 MB or smaller.'),
          ),
        );
        return;
      }
      final duplicate = attachments.any(
        (item) =>
            item.fileName == file.name && item.bytes.length == bytes.length,
      );
      if (!duplicate) {
        added.add(FeedbackAttachment(fileName: file.name, bytes: bytes));
      }
    }
    if (!mounted) return;
    setState(() => attachments = [...attachments, ...added]);
  }

  String dateLabel(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/${value.year}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Feedback')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Send feedback',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: category,
            decoration: const InputDecoration(labelText: 'Category'),
            items: const [
              DropdownMenuItem(value: 'general', child: Text('General')),
              DropdownMenuItem(value: 'bug', child: Text('Report a problem')),
              DropdownMenuItem(value: 'suggestion', child: Text('Suggestion')),
              DropdownMenuItem(
                value: 'service',
                child: Text('Service feedback'),
              ),
            ],
            onChanged: (value) => setState(() => category = value ?? 'general'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: message,
            minLines: 4,
            maxLines: 8,
            maxLength: 2000,
            decoration: const InputDecoration(
              labelText: 'Message',
              hintText:
                  'Tell the system administrator what happened or what can be improved.',
              alignLabelWithHint: true,
            ),
          ),
          OutlinedButton.icon(
            onPressed: submitting ? null : pickAttachments,
            icon: const Icon(Icons.attach_file),
            label: Text('Add attachments (${attachments.length}/5)'),
          ),
          const Text(
            'Optional: PDF, JPG, PNG, WebP, DOC, or DOCX. Maximum 5 MB each.',
          ),
          if (attachments.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...attachments.asMap().entries.map(
              (entry) => Card(
                child: ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: Text(
                    entry.value.fileName,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(_fileSize(entry.value.bytes.lengthInBytes)),
                  trailing: IconButton(
                    tooltip: 'Remove attachment',
                    onPressed: submitting
                        ? null
                        : () => setState(() {
                            attachments = [...attachments]..removeAt(entry.key);
                          }),
                    icon: const Icon(Icons.close),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: submitting ? null : submit,
            icon: submitting
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send_outlined),
            label: const Text('Submit feedback'),
          ),
          const SizedBox(height: 28),
          Text('My feedback', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          FutureBuilder<List<UserFeedback>>(
            future: feedback,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              final items = snapshot.data ?? const [];
              if (items.isEmpty) {
                return const Text('No feedback submitted yet.');
              }
              return Column(
                children: items
                    .map(
                      (item) => Card(
                        child: ListTile(
                          title: Text(item.message),
                          subtitle: Text(
                            '${item.category} • ${dateLabel(item.createdAt)}\n'
                            'Status: ${item.status}'
                            '${item.attachmentPaths.isEmpty ? '' : '\n${item.attachmentPaths.length} attachment${item.attachmentPaths.length == 1 ? '' : 's'}'}'
                            '${item.adminResponse == null ? '' : '\nAdmin: ${item.adminResponse}'}',
                          ),
                          isThreeLine: item.adminResponse != null,
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

String _fileSize(int bytes) => bytes >= 1024 * 1024
    ? '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB'
    : '${(bytes / 1024).toStringAsFixed(1)} KB';
