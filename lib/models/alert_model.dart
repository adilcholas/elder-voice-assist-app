class AlertModel {
  final String id;
  final String elderName;
  final String alertType;
  final DateTime timestamp;
  final String location;
  final bool isActive;

  AlertModel({
    required this.id,
    required this.elderName,
    required this.alertType,
    required this.timestamp,
    required this.location,
    this.isActive = true,
  });
}
