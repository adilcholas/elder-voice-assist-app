import 'dart:convert';

enum AlertStatus { active, acknowledged, resolved }

enum AlertType { emergency, voiceDistress, medicationMissed }

class AlertModel {
  final String id;
  final String elderName;
  final AlertType type;
  final DateTime timestamp;
  final String location;
  AlertStatus status;

  AlertModel({
    required this.id,
    required this.elderName,
    required this.type,
    required this.timestamp,
    required this.location,
    this.status = AlertStatus.active,
  });

  /// Convert to Map for persistence
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'elderName': elderName,
      'type': type.name,
      'timestamp': timestamp.toIso8601String(),
      'location': location,
      'status': status.name,
    };
  }

  /// Restore from Map
  factory AlertModel.fromMap(Map<String, dynamic> map) {
    return AlertModel(
      id: map['id'],
      elderName: map['elderName'],
      type: AlertType.values.firstWhere((e) => e.name == map['type']),
      timestamp: DateTime.parse(map['timestamp']),
      location: map['location'],
      status: AlertStatus.values.firstWhere((e) => e.name == map['status']),
    );
  }

  /// Encode to JSON
  String toJson() => jsonEncode(toMap());

  /// Decode from JSON
  factory AlertModel.fromJson(String source) =>
      AlertModel.fromMap(jsonDecode(source));
}
