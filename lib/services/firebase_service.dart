import 'package:firebase_messaging/firebase_messaging.dart';
import 'notification_service.dart';
import 'firebase_background_handler.dart';

class FirebaseService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static Future<void> initialize() async {
    await _messaging.requestPermission();

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final data = message.data;

      NotificationService().showAlertNotification(
        alertId: data['alertId'],
        elderName: data['elderName'],
        alertType: data['alertType'],
        location: data['location'],
      );
    });

    final initialMessage =
    await FirebaseMessaging.instance.getInitialMessage();

if (initialMessage != null) {
  final data = initialMessage.data;

  NotificationService().handleNotificationTap(
    data['alertId'],
  );
}
  }
}
