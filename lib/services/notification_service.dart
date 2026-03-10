import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  void Function(String alertId)? onNotificationTap;

  AndroidNotificationChannel channel = AndroidNotificationChannel(
    'emergency_alerts',
    'Emergency Alerts',
    description: 'Emergency alerts from elders',
    importance: Importance.max,
  );

  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const initSettings = InitializationSettings(android: androidSettings);

    await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    await _notifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (response) {
        if (response.payload == null) return;

        final data = jsonDecode(response.payload!);
        final alertId = data['alertId'] ?? '';

        if (alertId.isEmpty) return;

        if (onNotificationTap != null) {
          onNotificationTap!(alertId);
        }
      },
    );
  }

  Future<void> showAlertNotification({
    required String alertId,
    required String elderName,
    required String alertType,
    required String location,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'emergency_alerts',
      'Emergency Alerts',
      importance: Importance.max,
      priority: Priority.high,
    );

    const details = NotificationDetails(android: androidDetails);

    final payload = jsonEncode({"alertId": alertId});

    await _notifications.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: "🚨 Emergency Alert",
      body: "$elderName triggered $alertType\n📍 $location",
      notificationDetails: details,
      payload: payload,
    );
  }

  void handleNotificationTap(String alertId) {
    if (onNotificationTap != null) {
      onNotificationTap!(alertId);
    }
  }
}
