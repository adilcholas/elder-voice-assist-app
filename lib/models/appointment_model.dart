import 'dart:convert';

class AppointmentModel {
  final String id;
  final String title;
  final String doctorName;
  final String location;
  final DateTime dateTime;
  final String? notes;

  const AppointmentModel({
    required this.id,
    required this.title,
    required this.doctorName,
    required this.location,
    required this.dateTime,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'doctorName': doctorName,
      'location': location,
      'dateTime': dateTime.toIso8601String(),
      'notes': notes,
    };
  }

  factory AppointmentModel.fromMap(Map<String, dynamic> map) {
    return AppointmentModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      doctorName: map['doctorName'] ?? '',
      location: map['location'] ?? '',
      dateTime: DateTime.tryParse(map['dateTime'] ?? '') ?? DateTime.now(),
      notes: map['notes'],
    );
  }

  String toJson() => jsonEncode(toMap());

  factory AppointmentModel.fromJson(String source) => AppointmentModel.fromMap(jsonDecode(source));
}
