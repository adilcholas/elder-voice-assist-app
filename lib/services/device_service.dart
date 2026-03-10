import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DeviceService {

  final _db = FirebaseFirestore.instance;

  Future<void> saveToken(String userId) async {

    final token = await FirebaseMessaging.instance.getToken();

    if (token == null) return;

    await _db.collection("users").doc(userId).update({
      "deviceToken": token
    });
  }

}