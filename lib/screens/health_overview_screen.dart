import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/alert_provider.dart';
import '../providers/medication_provider.dart';
import '../providers/role_provider.dart';
import '../utils/app_colors.dart';
import '../utils/app_spacing.dart';
import '../utils/app_typography.dart';

class HealthOverviewScreen extends StatelessWidget {
  const HealthOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final alertProvider = context.watch<AlertProvider>();
    final medProvider = context.watch<MedicationProvider>();
    final roleProvider = context.watch<RoleProvider>();
    final name = roleProvider.userName.isNotEmpty
        ? roleProvider.userName
        : 'User';

    final totalAlerts = alertProvider.alerts.length;
    final resolvedAlerts = alertProvider.alerts
        .where((a) => a.status.name == 'resolved')
        .length;
    final activeMeds = medProvider.activeMedications.length;
    final overdueCount = medProvider.overdueMedications.length;
    final takenToday = medProvider.activeMedications.where((m) {
      if (m.lastTaken == null) return false;
      final now = DateTime.now();
      return m.lastTaken!.year == now.year &&
          m.lastTaken!.month == now.month &&
          m.lastTaken!.day == now.day;
    }).length;

    final safetyScore = _calculateSafetyScore(
      overdueCount: overdueCount,
      activeAlerts: alertProvider.activeAlerts.length,
      escalatedAlerts: alertProvider.escalatedAlerts.length,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Overview'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Safety Score Card
            _SafetyScoreCard(score: safetyScore, name: name),

            const SizedBox(height: AppSpacing.lg),

            Text('Today\'s Summary', style: AppTypography.heading),
            const SizedBox(height: AppSpacing.md),

            /// Stats Grid
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: AppSpacing.md,
              mainAxisSpacing: AppSpacing.md,
              childAspectRatio: 1.4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _StatCard(
                  icon: Icons.medication_rounded,
                  label: 'Active Meds',
                  value: '$activeMeds',
                  color: AppColors.secondary,
                ),
                _StatCard(
                  icon: Icons.check_circle_outline,
                  label: 'Taken Today',
                  value: '$takenToday',
                  color: AppColors.success,
                ),
                _StatCard(
                  icon: Icons.alarm_off_rounded,
                  label: 'Overdue',
                  value: '$overdueCount',
                  color: overdueCount > 0 ? AppColors.error : AppColors.success,
                ),
                _StatCard(
                  icon: Icons.warning_amber_rounded,
                  label: 'Total Alerts',
                  value: '$totalAlerts',
                  color: AppColors.warning,
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.lg),

            /// Upcoming Medications
            Text('Upcoming Medications', style: AppTypography.heading),
            const SizedBox(height: AppSpacing.md),

            if (medProvider.activeMedications.isEmpty)
              _EmptyCard(
                icon: Icons.medication_outlined,
                message: 'No medications scheduled. Tap below to add one.',
                onTap: () => context.push('/elder/medications'),
              )
            else
              ...medProvider.activeMedications.take(4).map((med) {
                return _MedicationRow(
                  med: med,
                  onTap: () => context.push('/elder/medications'),
                );
              }),

            const SizedBox(height: AppSpacing.lg),

            /// Recent Alert History
            Text('Recent Alerts', style: AppTypography.heading),
            const SizedBox(height: AppSpacing.md),

            if (alertProvider.alerts.isEmpty)
              const _EmptyCard(
                icon: Icons.check_circle_outline,
                message: 'No alerts recorded. All is calm.',
              )
            else
              ...alertProvider.alerts.take(3).map((alert) {
                return _AlertHistoryRow(
                  elderName: alert.elderName,
                  type: alert.type.name,
                  timestamp: alert.timestamp,
                  status: alert.status.name,
                  isEscalated: alert.escalatedToEmergencyServices,
                );
              }),

            if (resolvedAlerts > 0)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.md),
                child: Center(
                  child: Text(
                    '$resolvedAlerts alert${resolvedAlerts > 1 ? 's' : ''} resolved successfully ✓',
                    style: const TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),

            const SizedBox(height: AppSpacing.lg),

            /// Quick Actions
            Text('Quick Actions', style: AppTypography.heading),
            const SizedBox(height: AppSpacing.md),

            SizedBox(
              width: double.infinity,
              height: AppSpacing.buttonHeight,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.medication_outlined),
                label: const Text('Manage Medications'),
                onPressed: () => context.push('/elder/medications'),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              height: AppSpacing.buttonHeight,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.mic),
                label: const Text('Open Voice Assistant'),
                onPressed: () => context.push('/elder/voice'),
              ),
            ),

            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  int _calculateSafetyScore({
    required int overdueCount,
    required int activeAlerts,
    required int escalatedAlerts,
  }) {
    int score = 100;
    score -= overdueCount * 10;
    score -= activeAlerts * 15;
    score -= escalatedAlerts * 25;
    return score.clamp(0, 100);
  }
}

class _SafetyScoreCard extends StatelessWidget {
  final int score;
  final String name;

  const _SafetyScoreCard({required this.score, required this.name});

  @override
  Widget build(BuildContext context) {
    final color = score >= 80
        ? AppColors.success
        : score >= 50
        ? AppColors.warning
        : AppColors.error;

    final label = score >= 80
        ? 'Excellent'
        : score >= 50
        ? 'Needs Attention'
        : 'Critical';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.15),
            color.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          /// Score Circle
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 3),
            ),
            child: Center(
              child: Text(
                '$score',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Safety Score',
                  style: TextStyle(
                    fontSize: 14,
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  score >= 80
                      ? '$name is doing great today'
                      : score >= 50
                      ? 'Some items need attention'
                      : 'Immediate attention required',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _MedicationRow extends StatelessWidget {
  final dynamic med;
  final VoidCallback onTap;

  const _MedicationRow({required this.med, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isOverdue = med.isOverdue as bool;
    final isDue = med.isDueNow as bool;
    final Color statusColor = isOverdue
        ? AppColors.error
        : isDue
        ? AppColors.warning
        : AppColors.success;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: statusColor.withValues(alpha: 0.3)),
          color: statusColor.withValues(alpha: 0.08),
        ),
        child: Row(
          children: [
            Icon(Icons.medication_rounded, color: statusColor, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    med.name as String,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    med.dosage as String,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isOverdue
                    ? 'Overdue'
                    : isDue
                    ? 'Due Now'
                    : 'On Track',
                style: TextStyle(
                  color: statusColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertHistoryRow extends StatelessWidget {
  final String elderName;
  final String type;
  final DateTime timestamp;
  final String status;
  final bool isEscalated;

  const _AlertHistoryRow({
    required this.elderName,
    required this.type,
    required this.timestamp,
    required this.status,
    required this.isEscalated,
  });

  @override
  Widget build(BuildContext context) {
    final color = status == 'resolved'
        ? AppColors.success
        : status == 'escalated'
        ? AppColors.error
        : AppColors.warning;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        color: color.withValues(alpha: 0.08),
      ),
      child: Row(
        children: [
          Icon(
            isEscalated ? Icons.local_hospital : Icons.warning_amber_rounded,
            color: color,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type.toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  _formatTime(timestamp),
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
          Text(
            isEscalated ? 'Escalated' : status,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.day}/${dt.month}  '
        '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String message;
  final VoidCallback? onTap;

  const _EmptyCard({required this.icon, required this.message, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.lightTextSecondary.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 40, color: AppColors.lightTextSecondary),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.lightTextSecondary,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
