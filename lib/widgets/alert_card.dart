import 'package:flutter/material.dart';
import '../models/alert_model.dart';

class AlertCard extends StatelessWidget {
  final AlertModel alert;
  final VoidCallback onTap;

  const AlertCard({
    super.key,
    required this.alert,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          Icons.warning,
          color: alert.status == AlertStatus.active ? Colors.red : Colors.green,
          size: 40,
        ),
        title: Text(
          alert.elderName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          "${alert.type.name.toUpperCase()} • ${alert.location}",
        ),
        trailing: Text(
          _formatTime(alert.timestamp),
          style: const TextStyle(fontSize: 12),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return "${time.hour}:${time.minute.toString().padLeft(2, '0')}";
  }
}
