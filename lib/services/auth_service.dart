import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_profile.dart';
import '../models/user_role.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserProfile?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return UserProfile.fromMap(doc.data()!, doc.id);
      }
    } catch (e) {
      print('Error getting user profile: $e');
    }
    return null;
  }

  Future<UserProfile?> loginUser(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    if (credential.user != null) {
      return await getUserProfile(credential.user!.uid);
    }
    return null;
  }

  Future<UserProfile?> registerUser({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    
    if (credential.user != null) {
      final uid = credential.user!.uid;

      // Generate invite code for elders
      String inviteCode = '';
      if (role == UserRole.elder) {
        inviteCode = _generateInviteCode();
      }

      final profile = UserProfile(
        uid: uid,
        email: email,
        name: name,
        role: role,
        inviteCode: inviteCode,
      );

      await _firestore.collection('users').doc(uid).set(profile.toMap());
      return profile;
    }
    return null;
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  String _generateInviteCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(Iterable.generate(
        6, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
  }

  Future<bool> linkElder(String caregiverUid, String elderInviteCode) async {
    try {
      // Find the elder with the given invite code
      final query = await _firestore
          .collection('users')
          .where('inviteCode', isEqualTo: elderInviteCode)
          .where('role', isEqualTo: UserRole.elder.name)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final elderDoc = query.docs.first;
        final elderUid = elderDoc.id;

        // Update caregiver's linkedUserId
        await _firestore
            .collection('users')
            .doc(caregiverUid)
            .update({'linkedUserId': elderUid});

        // Update elder's linkedUserId
        await _firestore
            .collection('users')
            .doc(elderUid)
            .update({'linkedUserId': caregiverUid});
        return true;
      }
      return false; // Invite code not found
    } catch (e) {
      print('Error linking elder: $e');
      return false;
    }
  }

  Future<UserProfile?> getLinkedUserProfile(String linkedUserId) async {
    return await getUserProfile(linkedUserId);
  }
}