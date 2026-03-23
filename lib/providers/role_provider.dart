import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_role.dart';

class RoleProvider extends ChangeNotifier {
  static const _roleKey = 'user_role';
  static const _nameKey = 'user_name';
  static const _phoneKey = 'user_phone';
  static const _caregiverPhoneKey = 'caregiver_phone';

  UserRole? _role;
  String _userName = '';
  String _userPhone = '';
  String _caregiverPhone = '';

  UserRole? get role => _role;
  String get userName => _userName;
  String get userPhone => _userPhone;
  String get caregiverPhone => _caregiverPhone;

  bool get isElder => _role == UserRole.elder;
  bool get isCaregiver => _role == UserRole.caregiver;

  RoleProvider() {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final savedRole = prefs.getString(_roleKey);
    _userName = prefs.getString(_nameKey) ?? '';
    _userPhone = prefs.getString(_phoneKey) ?? '';
    _caregiverPhone = prefs.getString(_caregiverPhoneKey) ?? '';

    if (savedRole == UserRole.elder.name) {
      _role = UserRole.elder;
    } else if (savedRole == UserRole.caregiver.name) {
      _role = UserRole.caregiver;
    }
    notifyListeners();
  }

  Future<void> setRole(
    UserRole role, {
    String name = '',
    String phone = '',
  }) async {
    _role = role;
    if (name.isNotEmpty) _userName = name;
    if (phone.isNotEmpty) _userPhone = phone;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_roleKey, role.name);
    if (name.isNotEmpty) await prefs.setString(_nameKey, name);
    if (phone.isNotEmpty) await prefs.setString(_phoneKey, phone);
    notifyListeners();
  }

  Future<void> updateProfile({
    String? name,
    String? phone,
    String? caregiverPhone,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (name != null) {
      _userName = name;
      await prefs.setString(_nameKey, name);
    }
    if (phone != null) {
      _userPhone = phone;
      await prefs.setString(_phoneKey, phone);
    }
    if (caregiverPhone != null) {
      _caregiverPhone = caregiverPhone;
      await prefs.setString(_caregiverPhoneKey, caregiverPhone);
    }
    notifyListeners();
  }

  Future<void> clearRole() async {
    _role = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_roleKey);
    notifyListeners();
  }
}
