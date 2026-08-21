import 'package:flutter/material.dart';

import '../data/remote/notification_repository.dart';
import '../data/remote/supabase_service.dart';
import '../screens/notification_screen.dart';

class NotificationButton extends StatefulWidget {
  const NotificationButton({super.key});

  @override
  State<NotificationButton> createState() => _NotificationButtonState();
}

class _NotificationButtonState extends State<NotificationButton> {
  late Future<int> unreadCount;

  @override
  void initState() {
    super.initState();
    unreadCount = loadUnreadCount();
  }

  Future<int> loadUnreadCount() {
    final client = SupabaseService.client;
    if (client == null) return Future.value(0);
    return NotificationRepository(client).getUnreadCount();
  }

  Future<void> openNotifications() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationScreen()),
    );
    if (mounted) {
      setState(() {
        unreadCount = loadUnreadCount();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
      future: unreadCount,
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        return IconButton(
          onPressed: openNotifications,
          tooltip: 'Notifications',
          icon: Badge(
            isLabelVisible: count > 0,
            label: Text(count > 99 ? '99+' : '$count'),
            child: const Icon(Icons.notifications_outlined),
          ),
        );
      },
    );
  }
}
