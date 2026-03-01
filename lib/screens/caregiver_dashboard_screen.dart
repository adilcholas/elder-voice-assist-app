import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/alert_provider.dart';
import '../models/alert_model.dart';
import '../utils/app_spacing.dart';
import '../utils/app_typography.dart';
import '../widgets/priority_alert_card.dart';

class CaregiverDashboardScreen extends StatelessWidget {
  const CaregiverDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final alertProvider = context.watch<AlertProvider>();
    final alerts = _sortedAlerts(alertProvider.alerts);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Caregiver Dashboard"),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Header Section
            Text("Emergency Monitoring", style: AppTypography.heading),
            const SizedBox(height: 6),
            const Text(
              "Real-time alerts from connected elders",
              style: TextStyle(fontSize: 16),
            ),

            const SizedBox(height: AppSpacing.xl),

            /// Critical Alert Banner (if active exists)
            if (alerts.any((a) => a.status == AlertStatus.active))
              _CriticalBanner(
                count: alerts
                    .where((a) => a.status == AlertStatus.active)
                    .length,
              ),

            if (alerts.any((a) => a.status == AlertStatus.active))
              const SizedBox(height: AppSpacing.lg),

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
                              '/caregiver/alert-detail',
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
    );
  }

  /// 🔥 Priority Sorting Logic (Production Requirement)
  List<AlertModel> _sortedAlerts(List<AlertModel> alerts) {
    final sorted = [...alerts];
    sorted.sort((a, b) {
      int priority(AlertStatus s) {
        switch (s) {
          case AlertStatus.active:
            return 0;
          case AlertStatus.acknowledged:
            return 1;
          case AlertStatus.resolved:
            return 2;
        }
      }

      final statusCompare = priority(a.status).compareTo(priority(b.status));

      if (statusCompare != 0) return statusCompare;

      return b.timestamp.compareTo(a.timestamp);
    });

    return sorted;
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
        "🚨 $count Active Emergency Alert${count > 1 ? 's' : ''}",
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
            "All Elders Are Safe",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            "No active alerts at the moment.",
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}
