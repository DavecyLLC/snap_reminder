import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationsService {
  NotificationsService._();
  static final NotificationsService instance = NotificationsService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    final tzName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(tzName));

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(android: androidInit, iOS: iosInit);
    await _plugin.initialize(initSettings);

    _initialized = true;
  }

  int _notifId(String reminderId) => reminderId.hashCode & 0x7fffffff;

  Future<void> scheduleReminder({
    required String reminderId,
    required DateTime remindAt,
    required String title,
    required String body,
  }) async {
    await init();

    final id = _notifId(reminderId);
    await _plugin.cancel(id);

    final when = tz.TZDateTime.from(remindAt, tz.local);
    if (when.isBefore(tz.TZDateTime.now(tz.local))) return;

    const android = AndroidNotificationDetails(
      'photo_reminders',
      'Photo Reminders',
      channelDescription: 'Notifications for photo reminders',
      importance: Importance.max,
      priority: Priority.high,
    );

    const ios = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
      presentBadge: true,
    );

    const details = NotificationDetails(android: android, iOS: ios);

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      when,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: null,
    );
  }

  Future<void> cancelReminder(String reminderId) async {
    await init();
    await _plugin.cancel(_notifId(reminderId));
  }

  Future<void> cancelAll() async {
    await init();
    await _plugin.cancelAll();
  }
}
