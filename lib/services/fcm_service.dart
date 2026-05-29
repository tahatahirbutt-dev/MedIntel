import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('FCM background message: ${message.messageId}');
}

class FCMService {
  static final FCMService _instance = FCMService._internal();
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  factory FCMService() {
    return _instance;
  }

  FCMService._internal();

  Future<void> initialize() async {
    await _messaging.requestPermission(
      alert: true,
      announcement: true,
      badge: true,
      sound: true,
      criticalAlert: true,
      provisional: false,
    );

    final token = await _messaging.getToken();
    debugPrint('FCM Token: $token');

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'medicine_schedule',
      'Medicine Schedule',
      description: 'Notifications for medicine schedules',
      importance: Importance.high,
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await _notificationsPlugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
    );

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Received foreground message: ${message.notification?.title}');
      _showNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Notification opened: ${message.data}');
    });

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('Initial FCM message: ${initialMessage.data}');
    }
  }

  void _onDidReceiveNotificationResponse(NotificationResponse response) {
    debugPrint('Tapped local notification: ${response.payload}');
  }

  Future<void> _showNotification(RemoteMessage message) async {
    final notification = message.notification;
    final android = message.notification?.android;

    if (notification == null) {
      return;
    }

    await _notificationsPlugin.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'medicine_schedule',
          'Medicine Schedule',
          channelDescription: 'Notifications for medicine schedules',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          icon: android?.smallIcon ?? '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: message.data.toString(),
    );
  }

  Future<void> subscribeToScheduleNotifications() async {
    await _messaging.subscribeToTopic('medicine_schedule');
  }

  Future<void> unsubscribeFromScheduleNotifications() async {
    await _messaging.unsubscribeFromTopic('medicine_schedule');
  }
}
