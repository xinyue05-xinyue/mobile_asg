import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/remote/feedback_repository.dart';
import '../../data/remote/supabase_service.dart';
import '../../models/user_feedback.dart';

class FeedbackInboxScreen extends StatefulWidget {
  const FeedbackInboxScreen({super.key});

  @override
  State<FeedbackInboxScreen> createState() => _FeedbackInboxScreenState();
}

class _FeedbackInboxScreenState extends State<FeedbackInboxScreen> {
  late Future<List<UserFeedback>> feedback;

  @override
  void initState() {
    super.initState();
    feedback = load();
  }

  Future<List<UserFeedback>> load() =>
      FeedbackRepository(SupabaseService.client!).getAll();

  Future<void> review(UserFeedback item) async {
    var status = item.status;
    final response = TextEditingController(text: item.adminResponse ?? '');
    final save = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(item.userName),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${item.userRole} • ${item.category}'),
                const SizedBox(height: 12),
                Text(item.message),
                if (item.attachmentPaths.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Attachments',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  ...List.generate(item.attachmentPaths.length, (index) {
                    final name = index < item.attachmentNames.length
                        ? item.attachmentNames[index]
                        : 'Attachment ${index + 1}';
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.description_outlined),
                      title: Text(name, overflow: TextOverflow.ellipsis),
                      trailing: const Icon(Icons.open_in_new),
                      onTap: () => openAttachment(item.attachmentPaths[index]),
                    );
                  }),
                ],
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: const [
                    DropdownMenuItem(value: 'open', child: Text('Open')),
                    DropdownMenuItem(
                      value: 'reviewed',
                      child: Text('Reviewed'),
                    ),
                    DropdownMenuItem(
                      value: 'resolved',
                      child: Text('Resolved'),
                    ),
                  ],
                  onChanged: (value) =>
                      setDialogState(() => status = value ?? status),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: response,
                  minLines: 2,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Response to user',
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (save == true) {
      await FeedbackRepository(
        SupabaseService.client!,
      ).review(id: item.id, status: status, response: response.text);
      if (mounted) setState(() => feedback = load());
    }
    response.dispose();
  }

  Future<void> openAttachment(String path) async {
    try {
      final url = await FeedbackRepository(
        SupabaseService.client!,
      ).createAttachmentUrl(path);
      final opened = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
      if (!opened) throw StateError('Unable to open attachment.');
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to open attachment: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Feedback inbox')),
      body: FutureBuilder<List<UserFeedback>>(
        future: feedback,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Unable to load feedback: ${snapshot.error}'),
            );
          }
          final items = snapshot.data ?? const [];
          if (items.isEmpty) {
            return const Center(child: Text('No feedback yet.'));
          }
          return RefreshIndicator(
            onRefresh: () async {
              final refreshed = load();
              setState(() => feedback = refreshed);
              await refreshed;
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = items[index];
                return Card(
                  child: ListTile(
                    onTap: () => review(item),
                    leading: const Icon(Icons.feedback_outlined),
                    title: Text(item.userName),
                    subtitle: Text(
                      '${item.userRole} • ${item.category}\n${item.message}',
                    ),
                    isThreeLine: true,
                    trailing: Text(item.status),
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
