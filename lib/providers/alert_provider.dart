import 'dart:math';
import 'package:elder_voice_assist/services/location_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/alert_model.dart';

class AlertProvider extends ChangeNotifier {
  static const String _storageKey = 'persistent_alerts';

  final List<AlertModel> _alerts = [];

  List<AlertModel> get alerts => List.unmodifiable(_alerts);

  List<AlertModel> get activeAlerts =>
      _alerts.where((a) => a.status == AlertStatus.active).toList();

  /// MUST be called on app start
  Future<void> initialize() async {
    await _loadAlerts();
  }

  /// Trigger emergency (Elder side)
  Future<void> triggerEmergency({
    required String elderName,
    String? location,
  }) async {
    /// Fetch real GPS location if not provided
    final resolvedLocation =
        location ?? await LocationService.getCurrentLocation();

    final newAlert = AlertModel(
      id: _generateId(),
      elderName: elderName,
      type: AlertType.emergency,
      timestamp: DateTime.now(),
      location: resolvedLocation,
      status: AlertStatus.active,
    );

    _alerts.insert(0, newAlert);
    await _saveAlerts();
    notifyListeners();
  }

  /// Caregiver acknowledges alert
  Future<void> acknowledgeAlert(String alertId) async {
    final index = _alerts.indexWhere((a) => a.id == alertId);
    if (index != -1) {
      _alerts[index].status = AlertStatus.acknowledged;
      await _saveAlerts();
      notifyListeners();
    }
  }

  /// Resolve alert (after handling)
  Future<void> resolveAlert(String alertId) async {
    final index = _alerts.indexWhere((a) => a.id == alertId);
    if (index != -1) {
      _alerts[index].status = AlertStatus.resolved;
      await _saveAlerts();
      notifyListeners();
    }
  }

  /// Clear all alerts (admin/debug)
  Future<void> clearAllAlerts() async {
    _alerts.clear();
    await _saveAlerts();
    notifyListeners();
  }

  /// ---------------- STORAGE LAYER ----------------

  Future<void> _saveAlerts() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = _alerts.map((alert) => alert.toJson()).toList();
    await prefs.setStringList(_storageKey, encoded);
  }

  Future<void> _loadAlerts() async {
    final prefs = await SharedPreferences.getInstance();
    final storedList = prefs.getStringList(_storageKey);

    if (storedList == null) return;

    _alerts.clear();
    _alerts.addAll(storedList.map((json) => AlertModel.fromJson(json)));

    notifyListeners();
  }

  String _generateId() {
    return Random().nextInt(99999999).toString();
  }
}
