import 'dart:async';
import 'dart:math';
import 'package:elder_voice_assist/services/location_service.dart';
import 'package:elder_voice_assist/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/alert_model.dart';

class AlertProvider extends ChangeNotifier {
  static const String _storageKey = 'persistent_alerts';

  /// Timeout duration before escalating to emergency services (60 seconds)
  static const Duration _escalationTimeout = Duration(seconds: 60);

  final List<AlertModel> _alerts = [];

  /// Timer map: alertId → escalation timer
  final Map<String, Timer> _escalationTimers = {};

  List<AlertModel> get alerts => List.unmodifiable(_alerts);

  List<AlertModel> get activeAlerts =>
      _alerts.where((a) => a.status == AlertStatus.active).toList();

  List<AlertModel> get escalatedAlerts =>
      _alerts.where((a) => a.escalatedToEmergencyServices).toList();

  bool get hasActiveOrEscalated => _alerts.any(
    (a) => a.status == AlertStatus.active || a.status == AlertStatus.escalated,
  );

  /// MUST be called on app start
  Future<void> initialize() async {
    await _loadAlerts();
  }

  /// Trigger emergency (Elder side) — starts escalation countdown
  Future<void> triggerEmergency({
    required String elderName,
    String? location,
  }) async {
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

    // Show local notification to caregiver
    await NotificationService().showAlertNotification(
      alertId: newAlert.id,
      elderName: newAlert.elderName,
      alertType: newAlert.type.name,
      location: newAlert.location,
    );

    // Start escalation countdown — if caregiver doesn't respond in time
    _startEscalationTimer(newAlert.id, elderName, resolvedLocation);
  }

  /// Trigger medication missed alert
  Future<void> triggerMedicationMissed({
    required String elderName,
    required String medicationName,
    String? location,
  }) async {
    final resolvedLocation =
        location ?? await LocationService.getCurrentLocation();

    final newAlert = AlertModel(
      id: _generateId(),
      elderName: elderName,
      type: AlertType.medicationMissed,
      timestamp: DateTime.now(),
      location: resolvedLocation,
      status: AlertStatus.active,
      notes: 'Missed medication: $medicationName',
    );

    _alerts.insert(0, newAlert);
    await _saveAlerts();
    notifyListeners();

    await NotificationService().showAlertNotification(
      alertId: newAlert.id,
      elderName: newAlert.elderName,
      alertType: 'Medication Missed: $medicationName',
      location: newAlert.location,
    );

    _startEscalationTimer(newAlert.id, elderName, resolvedLocation);
  }

  /// Start escalation timer — caregiver must acknowledge before timeout
  void _startEscalationTimer(
    String alertId,
    String elderName,
    String location,
  ) {
    _escalationTimers[alertId]?.cancel();

    _escalationTimers[alertId] = Timer(_escalationTimeout, () async {
      final index = _alerts.indexWhere((a) => a.id == alertId);
      if (index == -1) return;

      final alert = _alerts[index];
      // Only escalate if still active (not yet acknowledged)
      if (alert.status == AlertStatus.active) {
        _alerts[index] = alert.copyWith(
          status: AlertStatus.escalated,
          escalatedToEmergencyServices: true,
        );
        await _saveAlerts();
        notifyListeners();

        // Notify about escalation
        await NotificationService().showEscalationNotification(
          alertId: alertId,
          elderName: elderName,
          location: location,
        );
      }
    });
  }

  /// Caregiver acknowledges alert — cancels escalation timer
  Future<void> acknowledgeAlert(String alertId) async {
    final index = _alerts.indexWhere((a) => a.id == alertId);
    if (index != -1) {
      _escalationTimers[alertId]?.cancel();
      _escalationTimers.remove(alertId);

      _alerts[index] = _alerts[index].copyWith(
        status: AlertStatus.acknowledged,
        acknowledgedAt: DateTime.now(),
      );
      await _saveAlerts();
      notifyListeners();
    }
  }

  /// Resolve alert (after handling)
  Future<void> resolveAlert(String alertId) async {
    final index = _alerts.indexWhere((a) => a.id == alertId);
    if (index != -1) {
      _escalationTimers[alertId]?.cancel();
      _escalationTimers.remove(alertId);

      _alerts[index] = _alerts[index].copyWith(status: AlertStatus.resolved);
      await _saveAlerts();
      notifyListeners();
    }
  }

  /// Create alert (used by background voice service / FCM)
  Future<void> createAlert(AlertModel alert) async {
    _alerts.insert(0, alert);
    await _saveAlerts();

    await NotificationService().showAlertNotification(
      alertId: alert.id,
      elderName: alert.elderName,
      alertType: alert.type.name,
      location: alert.location,
    );

    _startEscalationTimer(alert.id, alert.elderName, alert.location);
    notifyListeners();
  }

  /// Clear all alerts (admin/debug)
  Future<void> clearAllAlerts() async {
    for (final timer in _escalationTimers.values) {
      timer.cancel();
    }
    _escalationTimers.clear();
    _alerts.clear();
    await _saveAlerts();
    notifyListeners();
  }

  /// Get seconds remaining before escalation for a given alert
  /// Returns null if no active timer
  Duration? getEscalationTimeRemaining(String alertId) {
    // We can't query a Timer directly — we track start time instead
    return null; // handled via EscalationTimerWidget
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

    // Restart escalation timers for still-active alerts
    for (final alert in _alerts) {
      if (alert.status == AlertStatus.active) {
        final elapsed = DateTime.now().difference(alert.timestamp);
        final remaining = _escalationTimeout - elapsed;
        if (remaining > Duration.zero) {
          _startEscalationTimerWithDuration(
            alert.id,
            alert.elderName,
            alert.location,
            remaining,
          );
        } else {
          // Already overdue — escalate immediately
          _escalateImmediately(alert.id);
        }
      }
    }

    notifyListeners();
  }

  void _startEscalationTimerWithDuration(
    String alertId,
    String elderName,
    String location,
    Duration duration,
  ) {
    _escalationTimers[alertId]?.cancel();
    _escalationTimers[alertId] = Timer(duration, () async {
      final index = _alerts.indexWhere((a) => a.id == alertId);
      if (index == -1) return;
      final alert = _alerts[index];
      if (alert.status == AlertStatus.active) {
        _alerts[index] = alert.copyWith(
          status: AlertStatus.escalated,
          escalatedToEmergencyServices: true,
        );
        await _saveAlerts();
        notifyListeners();

        await NotificationService().showEscalationNotification(
          alertId: alertId,
          elderName: elderName,
          location: location,
        );
      }
    });
  }

  Future<void> _escalateImmediately(String alertId) async {
    final index = _alerts.indexWhere((a) => a.id == alertId);
    if (index == -1) return;
    final alert = _alerts[index];
    if (alert.status == AlertStatus.active) {
      _alerts[index] = alert.copyWith(
        status: AlertStatus.escalated,
        escalatedToEmergencyServices: true,
      );
      await _saveAlerts();
      notifyListeners();
    }
  }

  String _generateId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}';
  }

  @override
  void dispose() {
    for (final timer in _escalationTimers.values) {
      timer.cancel();
    }
    super.dispose();
  }
}
