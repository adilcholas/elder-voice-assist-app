import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/alert_model.dart';
import '../providers/alert_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/role_provider.dart';
import '../utils/app_colors.dart';
import '../utils/app_spacing.dart';
import '../utils/app_typography.dart';

class AlertDetailScreen extends StatelessWidget {
  const AlertDetailScreen({required this.alertId, this.alert, super.key});

  final String alertId;
  final AlertModel? alert;

  @override
  Widget build(BuildContext context) {
    final alertProvider = context.watch<AlertProvider>();

    // Try to get alert from provider if not passed directly
    AlertModel? resolvedAlert =
        alert ?? alertProvider.alerts.where((a) => a.id == alertId).firstOrNull;

    if (resolvedAlert == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Alert Detail')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline, size: 60),
              SizedBox(height: 16),
              Text(
                'Alert not found or already removed.',
                style: TextStyle(fontSize: 18),
              ),
            ],
          ),
        ),
      );
    }

    // Always use live data from provider (reflects real-time status changes)
    final liveAlert =
        alertProvider.alerts
            .where((a) => a.id == resolvedAlert.id)
            .firstOrNull ??
        resolvedAlert;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Alert'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Alert Status Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.cardPadding),
              decoration: BoxDecoration(
                color: _statusColor(liveAlert.status).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _statusColor(liveAlert.status).withValues(alpha: 0.4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _statusIcon(liveAlert.status),
                        color: _statusColor(liveAlert.status),
                        size: 28,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        liveAlert.type.name.toUpperCase().replaceAll('_', ' '),
                        style: AppTypography.title.copyWith(
                          color: _statusColor(liveAlert.status),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('Status: ', style: TextStyle(fontSize: 16)),
                      Text(
                        liveAlert.status.name.toUpperCase(),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _statusColor(liveAlert.status),
                        ),
                      ),
                    ],
                  ),
                  if (liveAlert.escalatedToEmergencyServices) ...[
                    const SizedBox(height: 8),
                    const Row(
                      children: [
                        Icon(
                          Icons.local_hospital,
                          color: AppColors.error,
                          size: 20,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Escalated to Emergency Services',
                          style: TextStyle(
                            color: AppColors.error,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            Text('Alert Information', style: AppTypography.heading),
            const SizedBox(height: AppSpacing.md),

            _infoTile('Elder Name', liveAlert.elderName),
            _infoTile('Location', liveAlert.location),
            _infoTile('Time', _formatTime(liveAlert.timestamp)),
            if (liveAlert.acknowledgedAt != null)
              _infoTile(
                'Acknowledged At',
                _formatTime(liveAlert.acknowledgedAt!),
              ),
            if (liveAlert.notes != null && liveAlert.notes!.isNotEmpty)
              _infoTile('Notes', liveAlert.notes!),

            const Spacer(),

            /// ACKNOWLEDGE BUTTON
            if (liveAlert.status == AlertStatus.active)
              SizedBox(
                width: double.infinity,
                height: AppSpacing.buttonHeight,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle),
                  label: const Text(
                    'Acknowledge Alert',
                    style: TextStyle(fontSize: 18),
                  ),
                  onPressed: () {
                    context.read<AlertProvider>().acknowledgeAlert(
                      liveAlert.id,
                    );
                  },
                ),
              ),

            if (liveAlert.status == AlertStatus.active)
              const SizedBox(height: AppSpacing.md),

            /// RESOLVE BUTTON
            if (liveAlert.status != AlertStatus.resolved)
              SizedBox(
                width: double.infinity,
                height: AppSpacing.buttonHeight,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.done_all),
                  label: const Text(
                    'Mark as Resolved',
                    style: TextStyle(fontSize: 18),
                  ),
                  onPressed: () {
                    context.read<AlertProvider>().resolveAlert(liveAlert.id);
                    context.pop();
                  },
                ),
              ),

            const SizedBox(height: AppSpacing.md),

            /// Call Elder
            SizedBox(
              width: double.infinity,
              height: AppSpacing.buttonHeight,
              child: TextButton.icon(
                icon: const Icon(Icons.call),
                label: const Text('Call Elder', style: TextStyle(fontSize: 18)),
                onPressed: () async {
                  final profile = context.read<RoleProvider>().profile;
                  if (profile?.linkedUserId != null) {
                    try {
                      final doc = await FirebaseFirestore.instance
                          .collection('users')
                          .doc(profile!.linkedUserId)
                          .get();
                      final phone = doc.data()?['phone'] as String?;
                      if (phone != null && phone.isNotEmpty) {
                        final uri = Uri.parse('tel:$phone');
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri);
                        } else {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Could not launch dialer.')),
                            );
                          }
                        }
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Elder phone number not found.')),
                          );
                        }
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Failed to fetch Elder number.')),
                        );
                      }
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No Elder linked.')),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(AlertStatus status) {
    switch (status) {
      case AlertStatus.active:
        return AppColors.error;
      case AlertStatus.acknowledged:
        return AppColors.warning;
      case AlertStatus.resolved:
        return AppColors.success;
      case AlertStatus.escalated:
        return AppColors.error;
    }
  }

  IconData _statusIcon(AlertStatus status) {
    switch (status) {
      case AlertStatus.active:
        return Icons.warning_rounded;
      case AlertStatus.acknowledged:
        return Icons.visibility;
      case AlertStatus.resolved:
        return Icons.check_circle;
      case AlertStatus.escalated:
        return Icons.local_hospital;
    }
  }

  String _formatTime(DateTime time) {
    return '${time.day}/${time.month}/${time.year} • '
        '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
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
