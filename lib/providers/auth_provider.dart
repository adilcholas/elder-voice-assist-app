import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_profile.dart';
import '../models/user_role.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  
  User? _firebaseUser;
  UserProfile? _userProfile;
  bool _isLoading = true;

  User? get firebaseUser => _firebaseUser;
  UserProfile? get profile => _userProfile;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _firebaseUser != null && _userProfile != null;

  UserRole? get role => _userProfile?.role;
  bool get isElder => role == UserRole.elder;
  bool get isCaregiver => role == UserRole.caregiver;

  AuthProvider() {
    _init();
  }

  void _init() {
    _authService.authStateChanges.listen((user) async {
      _firebaseUser = user;
      if (user != null) {
        await _fetchUserProfile(user.uid);
      } else {
        _userProfile = null;
        _isLoading = false;
        notifyListeners();
      }
    });
  }

  Future<void> _fetchUserProfile(String uid) async {
    _isLoading = true;
    notifyListeners();
    
    _userProfile = await _authService.getUserProfile(uid);
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> refreshProfile() async {
    if (_firebaseUser != null) {
      await _fetchUserProfile(_firebaseUser!.uid);
    }
  }

  Future<void> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      _userProfile = await _authService.loginUser(email, password);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      _userProfile = await _authService.registerUser(
        name: name,
        email: email,
        password: password,
        role: role,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    await _authService.logout();
    _userProfile = null;
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> linkElder(String elderInviteCode) async {
    if (!isCaregiver || _firebaseUser == null) return false;
    _isLoading = true;
    notifyListeners();
    bool success = false;
    try {
      success = await _authService.linkElder(_firebaseUser!.uid, elderInviteCode);
      if (success) {
        await refreshProfile();
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return success;
  }
}
