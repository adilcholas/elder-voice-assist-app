import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserService {

  final _db = FirebaseFirestore.instance;

  Future<void> createUser(UserModel user) async {

    await _db.collection('users').doc(user.id).set(
      user.toJson(),
    );
  }

  Future<UserModel?> getUser(String uid) async {

    final doc = await _db.collection('users').doc(uid).get();

    if (!doc.exists) return null;

    return UserModel.fromFirestore(doc.data()!, doc.id);
  }

}