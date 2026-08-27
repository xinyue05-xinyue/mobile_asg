import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/remote/feedback_repository.dart';
import '../data/remote/supabase_service.dart';
import '../models/user_feedback.dart';
import '../widgets/event_schedule.dart';

class FeedbackDetailScreen extends StatefulWidget {
  const FeedbackDetailScreen({super.key, required this.item});
  final UserFeedback item;
  @override
  State<FeedbackDetailScreen> createState() => _FeedbackDetailScreenState();
}

class _FeedbackDetailScreenState extends State<FeedbackDetailScreen> {
  late UserFeedback item = widget.item;
  Timer? timer;
  bool loading = false;
  List<Map<String, dynamic>> replies = [];
  bool historyUnavailable = false;
  @override
  void initState() {
    super.initState();
    refresh();
    timer = Timer.periodic(const Duration(seconds: 10), (_) => refresh());
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> refresh() async {
    if (loading) return;
    loading = true;
    try {
      final client = SupabaseService.client;
      if (client == null) return;
      final row = await client
          .from('feedback')
          .select(FeedbackRepository.selection)
          .eq('id', item.id)
          .single();
      List<Map<String, dynamic>>? updatedReplies;
      try {
        updatedReplies = await FeedbackRepository(client).getReplies(item.id);
      } catch (_) {
        // Keep the latest legacy response visible until migration 021 is applied.
      }
      if (mounted) {
        setState(() {
          item = UserFeedback.fromMap(row);
          historyUnavailable = updatedReplies == null;
          if (updatedReplies != null) replies = updatedReplies;
        });
      }
    } catch (_) {
      // Keep the last visible response if a background refresh fails.
    } finally {
      loading = false;
    }
  }

  Future<void> open(String path) async {
    try {
      final url = await FeedbackRepository(
        SupabaseService.client!,
      ).createAttachmentUrl(path);
      if (!await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      )) {
        throw StateError('Cannot open document');
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to open document. Please try again.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Feedback details')),
    body: ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        ListTile(
          title: Text(item.statusLabel),
          subtitle: Text('${item.category} • ${eventDateTime(item.createdAt)}'),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SelectableText(item.message),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Administrator replies',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        if (replies.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(item.adminResponse ?? 'Awaiting a response.'),
            ),
          ),
        for (final reply in replies)
          Card(
            child: ListTile(
              title: Text('${reply['message']}'),
              subtitle: Text(
                'System administrator • ${eventDateTime(DateTime.parse(reply['created_at'] as String))}',
              ),
            ),
          ),
        if (historyUnavailable)
          const Text(
            'Reply history is temporarily unavailable. The latest saved response is shown.',
          ),
        const Text(
          'Responses refresh automatically every 10 seconds while this page is open.',
        ),
        for (var i = 0; i < item.attachmentPaths.length; i++)
          Card(
            child: ListTile(
              leading: const Icon(Icons.description_outlined),
              title: Text(
                i < item.attachmentNames.length
                    ? item.attachmentNames[i]
                    : 'Document ${i + 1}',
              ),
              trailing: const Icon(Icons.open_in_new),
              onTap: () => open(item.attachmentPaths[i]),
            ),
          ),
      ],
    ),
  );
}
