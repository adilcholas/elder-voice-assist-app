import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/alert_provider.dart';
import '../utils/app_colors.dart';
import '../utils/app_spacing.dart';
import '../utils/app_typography.dart';
import '../widgets/emergency_button.dart';

class ElderHomeScreen extends StatelessWidget {
  const ElderHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final alertProvider = context.watch<AlertProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Elder Assistant"),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.go('/settings'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            /// Reassurance Header (Important for elderly UX)
            Text(
              "You are Safe.\nHow can I assist you?",
              textAlign: TextAlign.center,
              style: AppTypography.heading,
            ),

            const SizedBox(height: AppSpacing.xxl),

            /// EMERGENCY BUTTON (CORE FEATURE)
            Center(
              child: EmergencyButton(
                onPressed: () async {
                  await alertProvider.triggerEmergency(elderName: "Elder User");

                  context.go('/elder/emergency');
                },
              ),
            ),

            const SizedBox(height: AppSpacing.xxl),

            /// Voice Assistant Button (Secondary)
            SizedBox(
              width: double.infinity,
              height: AppSpacing.largeButtonHeight,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.mic, size: 28),
                label: const Text("Start Voice Assistant"),
                onPressed: () => context.go('/elder/voice'),
              ),
            ),

            const Spacer(),

            /// Active Alert Indicator (Real-time)
            if (alertProvider.activeAlerts.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  "Emergency alert is active. Help is on the way.",
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
