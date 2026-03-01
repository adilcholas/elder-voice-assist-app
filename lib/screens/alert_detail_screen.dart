import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/alert_model.dart';
import '../providers/alert_provider.dart';
import '../utils/app_colors.dart';
import '../utils/app_spacing.dart';
import '../utils/app_typography.dart';

class AlertDetailScreen extends StatelessWidget {
  const AlertDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final alert = GoRouterState.of(context).extra as AlertModel?;

    if (alert == null) {
      return const Scaffold(body: Center(child: Text("No Alert Data")));
    }

    final alertProvider = context.watch<AlertProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text("Emergency Alert")),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 🔴 Alert Status Card (High-Fidelity + Warm Theme)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.cardPadding),
              decoration: BoxDecoration(
                color: _statusColor(alert.status).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _statusColor(alert.status).withValues(alpha: 0.4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alert.type.name.toUpperCase(),
                    style: AppTypography.title.copyWith(
                      color: _statusColor(alert.status),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text("Status: ", style: TextStyle(fontSize: 16)),
                      Text(
                        alert.status.name.toUpperCase(),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _statusColor(alert.status),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            /// Elder Info Section
            Text("Alert Information", style: AppTypography.heading),
            const SizedBox(height: AppSpacing.md),

            _infoTile("Elder Name", alert.elderName),
            _infoTile("Location", alert.location),
            _infoTile("Time", _formatTime(alert.timestamp)),

            const Spacer(),

            /// 🟠 PRIMARY ACTION — ACKNOWLEDGE (NEW)
            SizedBox(
              width: double.infinity,
              height: AppSpacing.buttonHeight,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.check_circle),
                label: const Text(
                  "Acknowledge Alert",
                  style: TextStyle(fontSize: 18),
                ),
                onPressed: alert.status == AlertStatus.active
                    ? () {
                        context.read<AlertProvider>().acknowledgeAlert(
                          alert.id,
                        );
                      }
                    : null,
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            /// 🟢 RESOLVE BUTTON (CRITICAL FOR LIFECYCLE)
            SizedBox(
              width: double.infinity,
              height: AppSpacing.buttonHeight,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.done_all),
                label: const Text(
                  "Mark as Resolved",
                  style: TextStyle(fontSize: 18),
                ),
                onPressed: alert.status != AlertStatus.resolved
                    ? () {
                        context.read<AlertProvider>().resolveAlert(alert.id);
                        context.pop(); // GoRouter safe back
                      }
                    : null,
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            /// Secondary Actions (Existing but improved)
            SizedBox(
              width: double.infinity,
              height: AppSpacing.buttonHeight,
              child: TextButton.icon(
                icon: const Icon(Icons.call),
                label: const Text("Call Elder", style: TextStyle(fontSize: 18)),
                onPressed: () {
                  // Future: phone integration / VoIP
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Status Color Logic (Production UX)
  Color _statusColor(AlertStatus status) {
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
    return "${time.day}/${time.month}/${time.year} • "
        "${time.hour}:${time.minute.toString().padLeft(2, '0')}";
  }

  Widget _infoTile(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
