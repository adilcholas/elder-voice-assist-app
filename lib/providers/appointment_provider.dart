import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/appointment_model.dart';
import 'package:add_2_calendar/add_2_calendar.dart';

class AppointmentProvider extends ChangeNotifier {
  static const String _storageKey = 'appointments';
  final List<AppointmentModel> _appointments = [];

  List<AppointmentModel> get appointments {
    final sorted = List<AppointmentModel>.from(_appointments);
    sorted.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    return sorted;
  }

  AppointmentProvider() {
    _loadAppointments();
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
}
