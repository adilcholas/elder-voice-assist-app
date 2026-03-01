import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../providers/role_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/alert_provider.dart';
import '../providers/background_listener_provider.dart';
import '../services/background_voice_service.dart';
import '../utils/app_spacing.dart';
import '../utils/app_typography.dart';
import '../utils/app_colors.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final roleProvider = context.watch<RoleProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final alertProvider = context.read<AlertProvider>();
    final bgListenerProvider = context.watch<BackgroundListenerProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// HEADER
            Text("App Preferences", style: AppTypography.heading),
            const SizedBox(height: AppSpacing.lg),

            /// CURRENT ROLE CARD (High-Fidelity)
            _SettingsCard(
              child: ListTile(
                leading: const Icon(Icons.person_outline, size: 28),
                title: const Text(
                  "Current Role",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  roleProvider.isElder
                      ? "Elder Mode (Voice Assistance Enabled)"
                      : roleProvider.isCaregiver
                      ? "Caregiver Mode (Monitoring Dashboard)"
                      : "Not Selected",
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    roleProvider.isElder
                        ? "ELDER"
                        : roleProvider.isCaregiver
                        ? "CAREGIVER"
                        : "NONE",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            /// THEME TOGGLE (Production Integration)
            _SettingsCard(
              child: SwitchListTile(
                secondary: const Icon(Icons.dark_mode_outlined, size: 28),
                title: const Text(
                  "Dark Theme",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  "Warm dark theme for better night visibility",
                ),
                value: themeProvider.isDarkMode,
                onChanged: (value) {
                  themeProvider.toggleTheme(value);
                },
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            /// BACKGROUND EMERGENCY LISTENING (CRITICAL FEATURE)
            _SettingsCard(
              child: SwitchListTile(
                secondary: const Icon(Icons.mic_none_rounded, size: 28),
                title: const Text(
                  "Background Emergency Listening",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  "Detect 'Help' even when app is minimized",
                ),
                value: bgListenerProvider.isRunning,
                onChanged: (value) async {
                  if (value) {
                    await BackgroundVoiceService.startService();
                    bgListenerProvider.startListening(alertProvider);
                  } else {
                    await BackgroundVoiceService.stopService();
                    bgListenerProvider.stopListening();
                  }
                },
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            /// CHANGE ROLE (Safe Navigation)
            _SettingsCard(
              child: ListTile(
                leading: const Icon(Icons.switch_account_outlined, size: 28),
                title: const Text(
                  "Change Role",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  "Switch between Elder and Caregiver modes",
                ),
                onTap: () {
                  roleProvider.clearRole();
                  context.go('/role-selection');
                },
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            /// CLEAR ALERT HISTORY (ADMIN SAFETY TOOL)
            _SettingsCard(
              child: ListTile(
                leading: const Icon(Icons.delete_outline, size: 28),
                title: const Text(
                  "Clear Alert History",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                subtitle: const Text("Remove all stored emergency alerts"),
                onTap: () async {
                  await alertProvider.clearAllAlerts();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Alert history cleared")),
                    );
                  }
                },
              ),
            ),

            /// Background Emergency Listening (CRITICAL FEATURE)
            SwitchListTile(
              secondary: const Icon(Icons.mic_none_rounded),
              title: const Text("Background Emergency Listening"),
              subtitle: const Text("Detect 'Help' even when app is minimized"),
              value: bgListenerProvider.isRunning,
              onChanged: (value) async {
                if (value) {
                  /// Request microphone permission FIRST (MANDATORY)
                  final micPermission = await Permission.microphone.request();

                  if (micPermission.isGranted) {
                    await BackgroundVoiceService.startService();
                    bgListenerProvider.startListening(alertProvider);
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Microphone permission is required for voice detection",
                          ),
                        ),
                      );
                    }
                  }
                } else {
                  await BackgroundVoiceService.stopService();
                  bgListenerProvider.stopListening();
                }
              },
            ),

            const Spacer(),

            /// APP INFO (PRODUCTION FOOTER)
            Center(
              child: Column(
                children: const [
                  Text(
                    "Aura - Elder Voice Assist",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Version 1.0 • Safety Assistant",
                    style: TextStyle(
                      color: AppColors.lightTextSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// REUSABLE HIGH-FIDELITY CARD (Design System Compliant)
class _SettingsCard extends StatelessWidget {
  final Widget child;

  const _SettingsCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.lightCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.2)),
      ),
      child: child,
    );
  }
}
