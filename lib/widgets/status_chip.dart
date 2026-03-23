import 'package:flutter/material.dart';
import '../models/alert_model.dart';
import '../utils/app_colors.dart';

class StatusChip extends StatelessWidget {
  final AlertStatus status;

  const StatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _getColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        _getLabel(status),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Color _getColor(AlertStatus status) {
    switch (status) {
      case AlertStatus.active:
        return AppColors.error;
      case AlertStatus.acknowledged:
        return AppColors.warning;
      case AlertStatus.resolved:
        return AppColors.success;
      case AlertStatus.escalated:
        return Colors.deepOrange;
    }
  }

  String _getLabel(AlertStatus status) {
    switch (status) {
      case AlertStatus.active:
        return 'ACTIVE';
      case AlertStatus.acknowledged:
        return 'ACKNOWLEDGED';
      case AlertStatus.resolved:
        return 'RESOLVED';
      case AlertStatus.escalated:
        return 'ESCALATED';
    }
  }
}
