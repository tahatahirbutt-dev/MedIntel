import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Owns the single [FlutterLocalNotificationsPlugin] instance used for both
/// instant (FCM foreground) and exact-time scheduled (medicine dose) local
/// notifications. There must only ever be one instance/initialize() call —
/// the native side keeps a single callback registration, so a second
/// initialized instance would silently overwrite the first's handlers.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static const String scheduleChannelId = 'medicine_schedule';
  static const String scheduleChannelName = 'Medicine Schedule';
  static const String scheduleChannelDescription =
      'Reminders for scheduled medicine doses';

  final FlutterLocalNotificationsPlugin plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _exactAlarmsAllowed = false;

  Future<void> initialize({
    DidReceiveNotificationResponseCallback? onNotificationTap,
  }) async {
    if (_initialized) return;
    _initialized = true;

    tz_data.initializeTimeZones();
    try {
      final timeZone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZone.identifier));
    } catch (e) {
      debugPrint('NotificationService: could not resolve device timezone, defaulting to UTC: $e');
    }

    const channel = AndroidNotificationChannel(
      scheduleChannelId,
      scheduleChannelName,
      description: scheduleChannelDescription,
      importance: Importance.max,
    );

    final androidPlugin = plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(channel);

    await plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        ),
      ),
      onDidReceiveNotificationResponse: onNotificationTap,
    );

    await androidPlugin?.requestNotificationsPermission();
    _exactAlarmsAllowed =
        await androidPlugin?.requestExactAlarmsPermission() ?? true;
  }

  Future<void> showNow({
    required int id,
    required String title,
    required String body,
    String? payload,
    String? androidSmallIcon,
  }) async {
    await plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          scheduleChannelId,
          scheduleChannelName,
          channelDescription: scheduleChannelDescription,
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          icon: androidSmallIcon ?? '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload,
    );
  }

  /// Schedules an exact-time local notification for a single medicine dose.
  /// No-ops for times already in the past.
  Future<void> scheduleDoseReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    if (!scheduledTime.isAfter(DateTime.now())) return;

    final tzTime = tz.TZDateTime.from(scheduledTime, tz.local);

    await plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tzTime,
      payload: payload,
      androidScheduleMode: _exactAlarmsAllowed
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          scheduleChannelId,
          scheduleChannelName,
          channelDescription: scheduleChannelDescription,
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          category: AndroidNotificationCategory.reminder,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          interruptionLevel: InterruptionLevel.timeSensitive,
        ),
      ),
    );
  }

  Future<void> cancel(int id) => plugin.cancel(id: id);

  Future<void> cancelAll(Iterable<int> ids) async {
    for (final id in ids) {
      await plugin.cancel(id: id);
    }
  }

  /// Deterministic notification id derived from a dose id, so the same dose
  /// always maps to the same id and can be cancelled later without having
  /// to keep a separate id-lookup table.
  static int doseNotificationId(String doseId) {
    return doseId.hashCode & 0x7fffffff;
  }
}
