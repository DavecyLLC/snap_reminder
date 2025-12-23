import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _ready = false;

  Future<void> init({
    required void Function(String reminderId) onTapReminder,
  }) async {
    try {
      tzdata.initializeTimeZones();

      const initSettings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      );

      await _plugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse resp) {
          final payload = resp.payload;
          if (payload == null || payload.isEmpty) return;
          final map = jsonDecode(payload) as Map<String, dynamic>;
          final id = map['id'] as String?;
          if (id != null) onTapReminder(id);
        },
      );

      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();

      _ready = true;
    } catch (e) {
      // On Windows, plugin can be unavailable depending on setup.
      _ready = false;
      if (kDebugMode) {
        // ignore: avoid_print
        print('NotificationService init skipped: $e');
      }
    }
  }

  int _notifId(String reminderId) => reminderId.hashCode & 0x7fffffff;

  Future<void> scheduleReminder({
    required String reminderId,
    required DateTime remindAt,
    required String note,
  }) async {
    if (!_ready) return;
    if (!remindAt.isAfter(DateTime.now())) return;

    const androidDetails = AndroidNotificationDetails(
      'pic_reminders',
      'Picture Reminders',
      channelDescription: 'Scheduled picture reminders',
      importance: Importance.max,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    final details =
        NotificationDetails(android: androidDetails, iOS: iosDetails);

    final payload = jsonEncode({'id': reminderId});

    await _plugin.zonedSchedule(
      _notifId(reminderId),
      'Picture Reminder',
      note.isEmpty ? 'Tap to view your photo.' : note,
      tz.TZDateTime.from(remindAt, tz.local),
      details,
      payload: payload,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelReminder(String reminderId) async {
    if (!_ready) return;
    await _plugin.cancel(_notifId(reminderId));
  }
}
