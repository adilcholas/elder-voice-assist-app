import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/alert_provider.dart';
import '../providers/medication_provider.dart';
import '../providers/role_provider.dart';
import '../utils/app_colors.dart';
import '../utils/app_spacing.dart';
import '../utils/app_typography.dart';
import '../widgets/emergency_button.dart';

class ElderHomeScreen extends StatelessWidget {
  const ElderHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final alertProvider = context.watch<AlertProvider>();
    final medProvider = context.watch<MedicationProvider>();
    final roleProvider = context.watch<RoleProvider>();
    final name = roleProvider.userName.isNotEmpty
        ? roleProvider.userName
        : 'Friend';

    final overdueCount = medProvider.overdueMedications.length;
    final dueCount = medProvider.dueMedications.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Elder Assistant'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Greeting
            Text('Hello, $name 👋', style: AppTypography.heading),
            const SizedBox(height: 4),
            Text(
              'You are safe. How can I assist you?',
              style: AppTypography.body,
            ),

            const SizedBox(height: AppSpacing.xl),

            /// EMERGENCY BUTTON (CORE FEATURE)
            Center(
              child: EmergencyButton(
                onPressed: () async {
                  await alertProvider.triggerEmergency(elderName: name);
                  if (context.mounted) {
                    context.push('/elder/emergency');
                  }
                },
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            /// Quick Action Cards
            Row(
              children: [
                Expanded(
                  child: _QuickCard(
                    icon: Icons.mic_rounded,
                    label: 'Voice\nAssistant',
                    color: AppColors.primary,
                    onTap: () => context.push('/elder/voice'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _QuickCard(
                    icon: Icons.favorite_outline,
                    label: 'Health\nOverview',
                    color: AppColors.success,
                    onTap: () => context.push('/elder/health'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      _QuickCard(
                        icon: Icons.medication_outlined,
                        label: 'Medications',
                        color: AppColors.secondary,
                        onTap: () => context.push('/elder/medications'),
                      ),
                      if (overdueCount > 0 || dueCount > 0)
                        Positioned(
                          top: -6,
                          right: -6,
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: const BoxDecoration(
                              color: AppColors.error,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${overdueCount + dueCount}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _QuickCard(
                    icon: Icons.calendar_month,
                    label: 'Doctor\nVisits',
                    color: Colors.deepPurple,
                    onTap: () => context.push('/elder/appointments'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.lg),

            /// Medication Overdue Warning
            if (overdueCount > 0)
              _StatusBanner(
                icon: Icons.medication_liquid,
                color: AppColors.error,
                message:
                    '$overdueCount medication${overdueCount > 1 ? 's are' : ' is'} overdue! Please take it now.',
                onTap: () => context.push('/elder/medications'),
              ),

            if (dueCount > 0 && overdueCount == 0)
              _StatusBanner(
                icon: Icons.alarm,
                color: AppColors.warning,
                message:
                    '$dueCount medication${dueCount > 1 ? 's are' : ' is'} due soon.',
                onTap: () => context.push('/elder/medications'),
              ),

            /// Active Alert Indicator
            if (alertProvider.activeAlerts.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.md),
                child: _StatusBanner(
                  icon: Icons.warning_amber_rounded,
                  color: AppColors.error,
                  message:
                      'Emergency alert is active. Help is on the way. Stay calm.',
                  onTap: () => context.push('/elder/emergency'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _QuickCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36, color: color),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String message;
  final VoidCallback? onTap;

  const _StatusBanner({
    required this.icon,
    required this.color,
    required this.message,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontSize: 16,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: color),
          ],
        ),
      ),
    );
  }
}
