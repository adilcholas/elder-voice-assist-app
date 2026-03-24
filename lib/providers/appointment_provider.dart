import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/appointment_model.dart';
import 'package:add_2_calendar/add_2_calendar.dart';
import '../providers/alert_provider.dart';
import '../providers/role_provider.dart';

class AppointmentProvider extends ChangeNotifier {
  static const String _storageKey = 'appointments';
  final List<AppointmentModel> _appointments = [];
  AlertProvider? _alertProvider;
  RoleProvider? _roleProvider;
  Timer? _checkTimer;
  final Set<String> _notifiedMissedApts = {};

  void updateDependencies(AlertProvider? alertProvider, RoleProvider? roleProvider) {
    _alertProvider = alertProvider;
    _roleProvider = roleProvider;
  }

  List<AppointmentModel> get appointments {
    final sorted = List<AppointmentModel>.from(_appointments);
    sorted.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    return sorted;
  }

  AppointmentProvider() {
    _loadAppointments();
    _startCheckTimer();
  }

  void _startCheckTimer() {
    _checkTimer?.cancel();
    _checkTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      final now = DateTime.now();
      for (final apt in _appointments) {
        // Assume appointment is missed if 1 hour past start time
        if (now.isAfter(apt.dateTime.add(const Duration(hours: 1)))) {
          if (!_notifiedMissedApts.contains(apt.id)) {
            _notifiedMissedApts.add(apt.id);
            if (_alertProvider != null && _roleProvider != null && _roleProvider!.isElder) {
              final elderName = _roleProvider!.userName.isNotEmpty 
                  ? _roleProvider!.userName : 'Elder User';
              _alertProvider!.triggerAppointmentMissed(
                elderName: elderName,
                appointmentName: apt.title,
                location: apt.location,
              );
            }
          }
        }
      }
    });
  }

  Future<void> addAppointment(AppointmentModel appointment) async {
    _appointments.add(appointment);
    await _saveAppointments();
    notifyListeners();
  }

  Future<void> addAppointmentToCalendar(AppointmentModel apt) async {
    final Event event = Event(
      title: apt.title,
      description: 'Doctor: ${apt.doctorName}\n${apt.notes ?? ''}',
      location: apt.location,
      startDate: apt.dateTime,
      endDate: apt.dateTime.add(const Duration(hours: 1)),
      allDay: false,
    );
    await Add2Calendar.addEvent2Cal(event);
  }

  Future<void> removeAppointment(String id) async {
    _appointments.removeWhere((a) => a.id == id);
    await _saveAppointments();
    notifyListeners();
  }

  Future<void> _saveAppointments() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = _appointments.map((a) => a.toJson()).toList();
    await prefs.setStringList(_storageKey, encoded);
  }

  Future<void> _loadAppointments() async {
    final prefs = await SharedPreferences.getInstance();
    final storedList = prefs.getStringList(_storageKey);
    if (storedList != null) {
      _appointments.clear();
      _appointments.addAll(storedList.map((json) => AppointmentModel.fromJson(json)));
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
    super.dispose();
  }
}
