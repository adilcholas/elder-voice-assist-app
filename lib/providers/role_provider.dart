import 'package:flutter/material.dart';
import '../models/user_role.dart';

class RoleProvider extends ChangeNotifier {
  UserRole? _role;

  UserRole? get role => _role;

  bool get isElder => _role == UserRole.elder;
  bool get isCaregiver => _role == UserRole.caregiver;

  void setRole(UserRole role) {
    _role = role;
    notifyListeners();
  }

  void clearRole() {
    _role = null;
    notifyListeners();
  }
}
