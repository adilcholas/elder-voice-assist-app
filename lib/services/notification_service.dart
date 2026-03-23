import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  void Function(String alertId)? onNotificationTap;

  final AndroidNotificationChannel _alertChannel =
      const AndroidNotificationChannel(
        'emergency_alerts',
        'Emergency Alerts',
        description: 'Emergency alerts from elders',
        importance: Importance.max,
        enableVibration: true,
        playSound: true,
      );

  final AndroidNotificationChannel _escalationChannel =
      const AndroidNotificationChannel(
        'escalation_alerts',
        'Escalation Alerts',
        description: 'Emergency services escalation notifications',
        importance: Importance.max,
        enableVibration: true,
        playSound: true,
      );

  final AndroidNotificationChannel _medicationChannel =
      const AndroidNotificationChannel(
        'medication_reminders',
        'Medication Reminders',
        description: 'Medication reminder notifications',
        importance: Importance.high,
      );

  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initSettings = InitializationSettings(android: androidSettings);

    final androidImpl = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    await androidImpl?.createNotificationChannel(_alertChannel);
    await androidImpl?.createNotificationChannel(_escalationChannel);
    await androidImpl?.createNotificationChannel(_medicationChannel);

    await _notifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (response) {
        if (response.payload == null) return;
        final data = jsonDecode(response.payload!);
        final alertId = data['alertId'] ?? '';
        if (alertId.isEmpty) return;
        onNotificationTap?.call(alertId);
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
      fullScreenIntent: true,
    );

    const details = NotificationDetails(android: androidDetails);
    final payload = jsonEncode({'alertId': alertId});

    await _notifications.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: '🚨 Emergency Alert',
      body: '$elderName triggered $alertType\n📍 $location',
      notificationDetails: details,
      payload: payload,
    );
  }

  /// Called when caregiver does NOT respond in time — escalated to emergency services
  Future<void> showEscalationNotification({
    required String alertId,
    required String elderName,
    required String location,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'escalation_alerts',
      'Escalation Alerts',
      importance: Importance.max,
      priority: Priority.high,
      fullScreenIntent: true,
    );

    const details = NotificationDetails(android: androidDetails);
    final payload = jsonEncode({'alertId': alertId});

    await _notifications.show(
      id: (DateTime.now().millisecondsSinceEpoch ~/ 1000) + 1,
      title: '🚨 ESCALATED TO EMERGENCY SERVICES',
      body:
          '$elderName — Caregiver did not respond. Emergency services alerted.\n📍 $location',
      notificationDetails: details,
      payload: payload,
    );
  }

  Future<void> showMedicationReminder({
    required String medicationName,
    required String dosage,
    required String scheduledTime,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'medication_reminders',
      'Medication Reminders',
      importance: Importance.high,
      priority: Priority.high,
    );

    const details = NotificationDetails(android: androidDetails);

    await _notifications.show(
      id: (DateTime.now().millisecondsSinceEpoch ~/ 1000) + 2,
      title: '💊 Medication Reminder',
      body:
          'Time to take $medicationName ($dosage) — scheduled at $scheduledTime',
      notificationDetails: details,
    );
  }

  void handleNotificationTap(String alertId) {
    onNotificationTap?.call(alertId);
  }
}
