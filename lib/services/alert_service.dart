import 'package:cloud_firestore/cloud_firestore.dart';

class AlertService {

  final _db = FirebaseFirestore.instance;

  Future<String> createAlert(Map<String, dynamic> alert) async {

    final doc = await _db.collection("alerts").add(alert);

    return doc.id;
  }

}