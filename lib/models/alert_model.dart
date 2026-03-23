import 'dart:convert';

enum AlertStatus { active, acknowledged, resolved, escalated }

enum AlertType { emergency, voiceDistress, medicationMissed, fallDetected }

class AlertModel {
  final String id;
  final String elderName;
  final AlertType type;
  final DateTime timestamp;
  final String location;
  AlertStatus status;
  DateTime? acknowledgedAt;
  bool escalatedToEmergencyServices;
  final String? notes;

  AlertModel({
    required this.id,
    required this.elderName,
    required this.type,
    required this.timestamp,
    required this.location,
    this.status = AlertStatus.active,
    this.acknowledgedAt,
    this.escalatedToEmergencyServices = false,
    this.notes,
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
      'acknowledgedAt': acknowledgedAt?.toIso8601String(),
      'escalatedToEmergencyServices': escalatedToEmergencyServices,
      'notes': notes,
    };
  }

  /// Restore from Map
  factory AlertModel.fromMap(Map<String, dynamic> map) {
    return AlertModel(
      id: map['id'],
      elderName: map['elderName'],
      type: AlertType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => AlertType.emergency,
      ),
      timestamp: DateTime.parse(map['timestamp']),
      location: map['location'] ?? 'Unknown',
      status: AlertStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => AlertStatus.active,
      ),
      acknowledgedAt: map['acknowledgedAt'] != null
          ? DateTime.tryParse(map['acknowledgedAt'])
          : null,
      escalatedToEmergencyServices:
          map['escalatedToEmergencyServices'] as bool? ?? false,
      notes: map['notes'],
    );
  }

  /// Encode to JSON
  String toJson() => jsonEncode(toMap());

  /// Decode from JSON
  factory AlertModel.fromJson(String source) =>
      AlertModel.fromMap(jsonDecode(source));

  AlertModel copyWith({
    AlertStatus? status,
    DateTime? acknowledgedAt,
    bool? escalatedToEmergencyServices,
    String? notes,
  }) {
    return AlertModel(
      id: id,
      elderName: elderName,
      type: type,
      timestamp: timestamp,
      location: location,
      status: status ?? this.status,
      acknowledgedAt: acknowledgedAt ?? this.acknowledgedAt,
      escalatedToEmergencyServices:
          escalatedToEmergencyServices ?? this.escalatedToEmergencyServices,
      notes: notes ?? this.notes,
    );
  }
}
