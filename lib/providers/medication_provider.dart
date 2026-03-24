import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/medication_model.dart';
import '../services/notification_service.dart';

class MedicationProvider extends ChangeNotifier {
  static const String _storageKey = 'medications';

  final List<MedicationModel> _medications = [];
  Timer? _reminderTimer;

  List<MedicationModel> get medications => List.unmodifiable(_medications);

  List<MedicationModel> get activeMedications =>
      _medications.where((m) => m.isActive).toList();

  List<MedicationModel> get dueMedications =>
      _medications.where((m) => m.isActive && m.isDueNow).toList();

  List<MedicationModel> get overdueMedications =>
      _medications.where((m) => m.isActive && m.isOverdue).toList();

  MedicationProvider() {
    _loadMedications();
    _startReminderTimer();
  }

  Future<void> addMedication(MedicationModel medication) async {
    // Compute initial nextDue
    final withDue = medication.copyWith(nextDue: medication.computeNextDue());
    _medications.add(withDue);
    await _saveMedications();
    notifyListeners();
  }

  Future<void> updateMedication(MedicationModel updated) async {
    final index = _medications.indexWhere((m) => m.id == updated.id);
    if (index != -1) {
      _medications[index] = updated.copyWith(nextDue: updated.computeNextDue());
      await _saveMedications();
      notifyListeners();
    }
  }

  Future<void> markAsTaken(String medicationId) async {
    final index = _medications.indexWhere((m) => m.id == medicationId);
    if (index != -1) {
      final med = _medications[index];
      final nextDue = med.computeNextDue();
      _medications[index] = med.copyWith(
        lastTaken: DateTime.now(),
        nextDue: nextDue,
      );
      await _saveMedications();
      notifyListeners();
    }
  }

  Future<void> removeMedication(String medicationId) async {
    _medications.removeWhere((m) => m.id == medicationId);
    await _saveMedications();
    notifyListeners();
  }

  Future<void> toggleActive(String medicationId) async {
    final index = _medications.indexWhere((m) => m.id == medicationId);
    if (index != -1) {
      final med = _medications[index];
      _medications[index] = med.copyWith(isActive: !med.isActive);
      await _saveMedications();
      notifyListeners();
    }
  }

  final Set<String> _notifiedDueKeys = {};

  /// Check overdue and notify every minute
  void _startReminderTimer() {
    _reminderTimer?.cancel();
    _reminderTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      for (final med in _medications) {
        if (med.isActive && med.isDueNow && !med.isOverdue && med.nextDue != null) {
          final alertKey = '${med.id}_${med.nextDue!.millisecondsSinceEpoch}';
          if (!_notifiedDueKeys.contains(alertKey)) {
            _notifiedDueKeys.add(alertKey);
            
            // Format time for notification
            final h = med.nextDue!.hour % 12 == 0 ? 12 : med.nextDue!.hour % 12;
            final suffix = med.nextDue!.hour < 12 ? 'AM' : 'PM';
            final formattedTime = '$h:${med.nextDue!.minute.toString().padLeft(2, '0')} $suffix';
            
            // Try to trigger Local Notification
            try {
              NotificationService().showMedicationReminder(
                medicationName: med.name,
                dosage: med.dosage,
                scheduledTime: formattedTime,
              );
            } catch (e) {
              // Ignore failure for notification call structure if importing fails
            }
          }
        }
      }
      notifyListeners(); // Triggers due/overdue recalculation
    });
  }

  Future<void> _saveMedications() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = _medications.map((m) => m.toJson()).toList();
    await prefs.setStringList(_storageKey, encoded);
  }

  Future<void> _loadMedications() async {
    final prefs = await SharedPreferences.getInstance();
    final storedList = prefs.getStringList(_storageKey);
    if (storedList == null) return;

    _medications.clear();
    _medications.addAll(
      storedList.map((json) => MedicationModel.fromJson(json)),
    );
    notifyListeners();
  }

  @override
  void dispose() {
    _reminderTimer?.cancel();
    super.dispose();
  }
}
