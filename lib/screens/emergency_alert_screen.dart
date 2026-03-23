import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/alert_provider.dart';
import '../utils/app_colors.dart';
import '../utils/app_spacing.dart';
import '../utils/app_typography.dart';

class EmergencyAlertScreen extends StatefulWidget {
  const EmergencyAlertScreen({super.key});

  @override
  State<EmergencyAlertScreen> createState() => _EmergencyAlertScreenState();
}

class _EmergencyAlertScreenState extends State<EmergencyAlertScreen> {
  Timer? _countdownTimer;
  int _secondsLeft = 60; // matches AlertProvider._escalationTimeout
  bool _escalated = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_secondsLeft > 0) {
          _secondsLeft--;
        } else {
          _escalated = true;
          timer.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final alertProvider = context.watch<AlertProvider>();
    final activeAlerts = alertProvider.activeAlerts;

    // If alert was escalated by AlertProvider, update local state
    if (!_escalated && alertProvider.escalatedAlerts.isNotEmpty) {
      _escalated = true;
    }

    return PopScope(
      canPop: false, // Prevent accidental back during emergency
      child: Scaffold(
        backgroundColor: AppColors.lightBackground,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                /// Top Icon
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

                Text(
                  'Emergency Alert Sent',
                  textAlign: TextAlign.center,
                  style: AppTypography.display,
                ),

                const SizedBox(height: AppSpacing.md),

                Text(
                  'Your caregiver has been notified.\nPlease stay calm. Help is on the way.',
                  textAlign: TextAlign.center,
                  style: AppTypography.body,
                ),

                const SizedBox(height: AppSpacing.xl),

                /// Escalation Status
                if (_escalated)
                  _EscalationBanner()
                else
                  _CountdownCard(secondsLeft: _secondsLeft),

                const SizedBox(height: AppSpacing.xl),

                /// Active Alert Info
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
                          'Active Emergency',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Time: ${_formatTime(activeAlerts.first.timestamp)}',
                          style: AppTypography.body,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Location: ${activeAlerts.first.location}',
                          style: AppTypography.body,
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: AppSpacing.xl),

                /// I'm Safe Button
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
                      // Use go() instead of push() to clear back stack
                      context.go('/elder/home');
                    },
                    child: const Text(
                      'I am Safe Now',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                TextButton(
                  onPressed: () => context.go('/elder/home'),
                  child: const Text('Return to Home'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.day}/${time.month}/${time.year} • '
        '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }
}

class _CountdownCard extends StatelessWidget {
  final int secondsLeft;

  const _CountdownCard({required this.secondsLeft});

  @override
  Widget build(BuildContext context) {
    final fraction = secondsLeft / 60.0;
    final urgentColor = secondsLeft < 20 ? AppColors.error : AppColors.warning;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: urgentColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: urgentColor.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          Text(
            'Caregiver Response Window',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: urgentColor,
            ),
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: fraction,
            backgroundColor: urgentColor.withValues(alpha: 0.2),
            color: urgentColor,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 8),
          Text(
            secondsLeft > 0
                ? '$secondsLeft seconds before escalation to emergency services'
                : 'Escalating to emergency services...',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: urgentColor),
          ),
        ],
      ),
    );
  }
}

class _EscalationBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.error),
      ),
      child: Column(
        children: const [
          Icon(Icons.local_hospital, color: AppColors.error, size: 40),
          SizedBox(height: 8),
          Text(
            '🚨 Emergency Services Alerted',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.error,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Caregiver did not respond in time.\nEmergency services have been notified.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15),
          ),
        ],
      ),
    );
  }
}
