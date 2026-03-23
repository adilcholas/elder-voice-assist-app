import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/alert_provider.dart';
import '../models/alert_model.dart';
import '../utils/app_colors.dart';
import '../utils/app_spacing.dart';
import '../utils/app_typography.dart';
import '../widgets/priority_alert_card.dart';

class CaregiverDashboardScreen extends StatelessWidget {
  const CaregiverDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final alertProvider = context.watch<AlertProvider>();
    final alerts = _sortedAlerts(alertProvider.alerts);

    final activeCount = alerts
        .where((a) => a.status == AlertStatus.active)
        .length;
    final escalatedCount = alerts
        .where((a) => a.escalatedToEmergencyServices)
        .length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Caregiver Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Trigger rebuild — alerts are real-time via Provider
          await Future.delayed(const Duration(milliseconds: 300));
        },
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Header
              Text('Emergency Monitoring', style: AppTypography.heading),
              const SizedBox(height: 6),
              const Text(
                'Real-time alerts from connected elders',
                style: TextStyle(fontSize: 16),
              ),

              const SizedBox(height: AppSpacing.md),

              /// Stats Row
              Row(
                children: [
                  _StatPill(
                    label: 'Active',
                    count: activeCount,
                    color: AppColors.error,
                  ),
                  const SizedBox(width: 10),
                  _StatPill(
                    label: 'Escalated',
                    count: escalatedCount,
                    color: Colors.deepOrange,
                  ),
                  const SizedBox(width: 10),
                  _StatPill(
                    label: 'Total',
                    count: alerts.length,
                    color: AppColors.secondary,
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.md),

              /// ESCALATED Banner (Critical - Emergency Services Alerted)
              if (escalatedCount > 0) _EscalatedBanner(count: escalatedCount),

              if (escalatedCount > 0) const SizedBox(height: AppSpacing.md),

              /// Critical Alert Banner
              if (activeCount > 0 && escalatedCount == 0)
                _CriticalBanner(count: activeCount),

              if (activeCount > 0 && escalatedCount == 0)
                const SizedBox(height: AppSpacing.md),

              /// Alert List
              Expanded(
                child: alerts.isEmpty
                    ? const _EmptyState()
                    : ListView.builder(
                        itemCount: alerts.length,
                        itemBuilder: (context, index) {
                          final alert = alerts[index];
                          return PriorityAlertCard(
                            alert: alert,
                            onTap: () {
                              context.push(
                                '/alertDetail/${alert.id}',
                                extra: alert,
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<AlertModel> _sortedAlerts(List<AlertModel> alerts) {
    final sorted = [...alerts];
    sorted.sort((a, b) {
      int priority(AlertModel m) {
        if (m.escalatedToEmergencyServices) return 0;
        switch (m.status) {
          case AlertStatus.active:
            return 1;
          case AlertStatus.acknowledged:
            return 2;
          case AlertStatus.escalated:
            return 0;
          case AlertStatus.resolved:
            return 3;
        }
      }

      final statusCompare = priority(a).compareTo(priority(b));
      if (statusCompare != 0) return statusCompare;
      return b.timestamp.compareTo(a.timestamp);
    });

    return sorted;
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatPill({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        '$count $label',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
}

class _EscalatedBanner extends StatelessWidget {
  final int count;
  const _EscalatedBanner({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.deepOrange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.deepOrange.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_hospital, color: Colors.deepOrange, size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '🚨 $count Alert${count > 1 ? 's' : ''} Escalated to Emergency Services\nCaregiver did not respond in time.',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.deepOrange,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CriticalBanner extends StatelessWidget {
  final int count;
  const _CriticalBanner({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
      ),
      child: Text(
        '🚨 $count Active Emergency Alert${count > 1 ? 's' : ''} — Respond Now',
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.red,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.health_and_safety_outlined, size: 64),
          SizedBox(height: 16),
          Text(
            'All Elders Are Safe',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'No active alerts at the moment.',
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}
