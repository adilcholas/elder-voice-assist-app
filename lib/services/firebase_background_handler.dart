import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'notification_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  final data = message.data;

  if (data.isEmpty) return;

  await NotificationService().showAlertNotification(
    alertId: data['alertId'] ?? '',
    elderName: data['elderName'] ?? 'Elder',
    alertType: data['alertType'] ?? 'Emergency',
    location: data['location'] ?? 'Unknown location',
  );
}