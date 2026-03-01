import 'package:flutter/material.dart';
import '../models/alert_model.dart';
import '../utils/app_colors.dart';
import '../utils/app_spacing.dart';
import '../utils/app_typography.dart';
import 'status_chip.dart';

class PriorityAlertCard extends StatelessWidget {
  final AlertModel alert;
  final VoidCallback onTap;

  const PriorityAlertCard({
    super.key,
    required this.alert,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = alert.status == AlertStatus.active;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        decoration: BoxDecoration(
          color: AppColors.lightCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _borderColor(alert.status).withValues(alpha: 0.4),
            width: isActive ? 2 : 1,
          ),
          boxShadow: [
            if (isActive)
              BoxShadow(
                color: AppColors.error.withValues(alpha: 0.08),
                blurRadius: 12,
                spreadRadius: 1,
              ),
          ],
        ),
        child: Row(
          children: [
            /// Priority Indicator (Visual Hierarchy)
            Container(
              width: 10,
              height: 70,
              decoration: BoxDecoration(
                color: _borderColor(alert.status),
                borderRadius: BorderRadius.circular(8),
              ),
            ),

            const SizedBox(width: AppSpacing.md),

            /// Alert Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// Elder Name
                  Text(alert.elderName, style: AppTypography.title),

                  const SizedBox(height: 6),

                  /// Alert Type
                  Text(
                    alert.type.name.toUpperCase(),
                    style: AppTypography.body,
                  ),

                  const SizedBox(height: 6),

                  /// Location
                  Text(
                    alert.location,
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: AppSpacing.sm),

            /// Right Section (Time + Status)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                StatusChip(status: alert.status),
                const SizedBox(height: 10),
                Text(
                  _formatTime(alert.timestamp),
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _borderColor(AlertStatus status) {
    switch (status) {
      case AlertStatus.active:
        return AppColors.error;
      case AlertStatus.acknowledged:
        return AppColors.warning;
      case AlertStatus.resolved:
        return AppColors.success;
    }
  }

  String _formatTime(DateTime time) {
    return "${time.hour}:${time.minute.toString().padLeft(2, '0')}";
  }
}
