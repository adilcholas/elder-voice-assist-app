import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/alert_provider.dart';
import '../utils/app_colors.dart';
import '../utils/app_spacing.dart';
import '../utils/app_typography.dart';

class EmergencyAlertScreen extends StatelessWidget {
  const EmergencyAlertScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final alertProvider = context.watch<AlertProvider>();
    final activeAlerts = alertProvider.activeAlerts;

    return PopScope(
      canPop: false, // Prevent accidental back
      child: Scaffold(
        backgroundColor: AppColors.lightBackground,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                /// Top Icon (Clear Emergency State)
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.warning_rounded,
                    size: 70,
                    color: AppColors.error,
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                /// Main Status Text (Reassurance for Elder)
                Text(
                  "Emergency Alert Sent",
                  textAlign: TextAlign.center,
                  style: AppTypography.display,
                ),

                const SizedBox(height: AppSpacing.md),

                Text(
                  "Your caregiver has been notified.\nPlease stay calm. Help is on the way.",
                  textAlign: TextAlign.center,
                  style: AppTypography.body,
                ),

                const SizedBox(height: AppSpacing.xxl),

                /// Active Alert Info (Real-time)
                if (activeAlerts.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.cardPadding),
                    decoration: BoxDecoration(
                      color: AppColors.lightCard,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          "Active Emergency",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Time: ${activeAlerts.first.timestamp}",
                          style: AppTypography.body,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Location: ${activeAlerts.first.location}",
                          style: AppTypography.body,
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: AppSpacing.xxl),

                /// Resolve / Cancel Button (MVP safety control)
                SizedBox(
                  width: double.infinity,
                  height: AppSpacing.buttonHeight,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                    ),
                    onPressed: () {
                      if (activeAlerts.isNotEmpty) {
                        alertProvider.resolveAlert(activeAlerts.first.id);
                      }
                      context.go('/elder/home');
                    },
                    child: const Text(
                      "I am Safe Now",
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                /// Secondary Action
                TextButton(
                  onPressed: () {
                    context.go('/elder/home');
                  },
                  child: const Text("Return to Home"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
