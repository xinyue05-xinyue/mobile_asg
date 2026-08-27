import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as timezone_data;
import 'package:timezone/timezone.dart' as timezone;

import '../../models/donation_event.dart';

class EventReminderService {
  EventReminderService._();

  static final EventReminderService instance = EventReminderService._();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _isSupported = false;

  Future<void> initialize() async {
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      return;
    }

    try {
      timezone_data.initializeTimeZones();
      try {
        timezone.setLocalLocation(timezone.getLocation('Asia/Kuala_Lumpur'));
      } on timezone.LocationNotFoundException {
        timezone.setLocalLocation(timezone.UTC);
      }
      const settings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      );
      _isSupported =
          await _notifications.initialize(settings: settings) ?? false;
    } catch (_) {
      _isSupported = false;
    }
  }

  Future<DateTime?> reminderFor(String eventId) async {
    final value = (await SharedPreferences.getInstance()).getString(
      _preferenceKey(eventId),
    );
    return value == null ? null : DateTime.tryParse(value)?.toLocal();
  }

  Future<void> schedule({
    required DonationEvent event,
    required DateTime reminderAt,
  }) async {
    if (!_isSupported) {
      throw StateError(
        'Event reminders are only available on a mobile device.',
      );
    }
    if (!reminderAt.isAfter(DateTime.now()) ||
        !reminderAt.isBefore(event.startsAt)) {
      throw ArgumentError('Choose a future time before the event starts.');
    }

    final permissionGranted = await _requestPermission();
    if (!permissionGranted) {
      throw StateError(
        'Notification permission is required to schedule a reminder.',
      );
    }

    await _notifications.zonedSchedule(
      id: _notificationId(event.id),
      title: 'Blood donation event reminder',
      body: '${event.title} starts soon at ${event.venue}.',
      scheduledDate: timezone.TZDateTime.from(reminderAt, timezone.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'event_reminders',
          'Event reminders',
          channelDescription: 'Reminders for registered blood donation events',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: 'event:${event.id}',
    );
    await (await SharedPreferences.getInstance()).setString(
      _preferenceKey(event.id),
      reminderAt.toUtc().toIso8601String(),
    );
  }

  Future<void> cancel(String eventId) async {
    if (_isSupported) {
      await _notifications.cancel(id: _notificationId(eventId));
    }
    await (await SharedPreferences.getInstance()).remove(
      _preferenceKey(eventId),
    );
  }

  Future<bool> _requestPermission() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return await _notifications
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()
              ?.requestNotificationsPermission() ??
          false;
    }
    return await _notifications
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >()
            ?.requestPermissions(alert: true, badge: true, sound: true) ??
        false;
  }

  String _preferenceKey(String eventId) => 'event_reminder_$eventId';

  int _notificationId(String eventId) {
    var hash = 2166136261;
    for (final codeUnit in eventId.codeUnits) {
      hash = ((hash ^ codeUnit) * 16777619) & 0x7fffffff;
    }
    return hash;
  }
}
