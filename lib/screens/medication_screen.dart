import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../models/medication_model.dart';
import '../providers/medication_provider.dart';
import '../providers/alert_provider.dart';
import '../providers/role_provider.dart';
import '../utils/app_colors.dart';
import '../utils/app_spacing.dart';
import '../utils/app_typography.dart';

class MedicationScreen extends StatelessWidget {
  const MedicationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final medProvider = context.watch<MedicationProvider>();

    final due = medProvider.dueMedications;
    final overdue = medProvider.overdueMedications;
    final all = medProvider.activeMedications;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medications'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddMedicationDialog(context),
            tooltip: 'Add Medication',
          ),
        ],
      ),
      body: all.isEmpty
          ? _EmptyMedications(onAdd: () => _showAddMedicationDialog(context))
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                /// Overdue Banner
                if (overdue.isNotEmpty) ...[
                  _SectionHeader(label: '⚠️ Overdue', color: AppColors.error),
                  const SizedBox(height: AppSpacing.sm),
                  ...overdue.map(
                    (m) => _MedicationCard(
                      medication: m,
                      onTaken: () =>
                          context.read<MedicationProvider>().markAsTaken(m.id),
                      onDelete: () => context
                          .read<MedicationProvider>()
                          .removeMedication(m.id),
                      onMissedAlert: () => _triggerMissedAlert(context, m),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],

                /// Due Now
                if (due.isNotEmpty) ...[
                  _SectionHeader(label: '🔔 Due Now', color: AppColors.warning),
                  const SizedBox(height: AppSpacing.sm),
                  ...due.map(
                    (m) => _MedicationCard(
                      medication: m,
                      onTaken: () =>
                          context.read<MedicationProvider>().markAsTaken(m.id),
                      onDelete: () => context
                          .read<MedicationProvider>()
                          .removeMedication(m.id),
                      onMissedAlert: () => _triggerMissedAlert(context, m),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],

                /// All scheduled
                _SectionHeader(
                  label: '💊 All Medications',
                  color: AppColors.secondary,
                ),
                const SizedBox(height: AppSpacing.sm),
                ...all.map(
                  (m) => _MedicationCard(
                    medication: m,
                    onTaken: () =>
                        context.read<MedicationProvider>().markAsTaken(m.id),
                    onDelete: () => context
                        .read<MedicationProvider>()
                        .removeMedication(m.id),
                    onMissedAlert: () => _triggerMissedAlert(context, m),
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddMedicationDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Medication'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Future<void> _triggerMissedAlert(
    BuildContext context,
    MedicationModel med,
  ) async {
    final alertProvider = context.read<AlertProvider>();
    final roleProvider = context.read<RoleProvider>();
    final name = roleProvider.userName.isNotEmpty
        ? roleProvider.userName
        : 'Elder User';

    await alertProvider.triggerMedicationMissed(
      elderName: name,
      medicationName: med.name,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Alert sent for missed ${med.name}'),
          backgroundColor: AppColors.warning,
        ),
      );
    }
  }

  void _showAddMedicationDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => const _AddMedicationSheet(),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final Color color;

  const _SectionHeader({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
    );
  }
}

class _MedicationCard extends StatelessWidget {
  final MedicationModel medication;
  final VoidCallback onTaken;
  final VoidCallback onDelete;
  final VoidCallback onMissedAlert;

  const _MedicationCard({
    required this.medication,
    required this.onTaken,
    required this.onDelete,
    required this.onMissedAlert,
  });

  @override
  Widget build(BuildContext context) {
    final isOverdue = medication.isOverdue;
    final isDue = medication.isDueNow && !isOverdue;
    final statusColor = isOverdue
        ? AppColors.error
        : isDue
        ? AppColors.warning
        : AppColors.success;

    final takenToday =
        medication.lastTaken != null &&
        medication.lastTaken!.day == DateTime.now().day &&
        medication.lastTaken!.month == DateTime.now().month;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: statusColor.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.medication_rounded,
                    color: statusColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(medication.name, style: AppTypography.title),
                      Text(
                        medication.dosage,
                        style: const TextStyle(
                          fontSize: 15,
                          color: AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusBadge(
                  label: isOverdue
                      ? 'Overdue'
                      : takenToday
                      ? 'Taken ✓'
                      : isDue
                      ? 'Due Now'
                      : 'Scheduled',
                  color: takenToday ? AppColors.success : statusColor,
                ),
              ],
            ),

            const SizedBox(height: 12),

            /// Times
            Row(
              children: [
                const Icon(
                  Icons.access_time,
                  size: 16,
                  color: AppColors.lightTextSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  medication.times.map((t) => t.formatted).join(', '),
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),

            if (medication.instructions != null) ...[
              const SizedBox(height: 4),
              Text(
                'Note: ${medication.instructions}',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.lightTextSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],

            if (medication.nextDue != null) ...[
              const SizedBox(height: 4),
              Text(
                'Next dose: ${_formatDateTime(medication.nextDue!)}',
                style: TextStyle(
                  fontSize: 13,
                  color: isOverdue
                      ? AppColors.error
                      : AppColors.lightTextSecondary,
                ),
              ),
            ],

            const SizedBox(height: 12),

            /// Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check, size: 18),
                    label: Text(takenToday ? 'Taken Today' : 'Mark Taken'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: takenToday
                          ? AppColors.success.withValues(alpha: 0.6)
                          : AppColors.success,
                      minimumSize: const Size(0, 44),
                    ),
                    onPressed: takenToday ? null : onTaken,
                  ),
                ),
                if (isOverdue) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.warning_amber, size: 18),
                      label: const Text('Alert'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        minimumSize: const Size(0, 44),
                      ),
                      onPressed: onMissedAlert,
                    ),
                  ),
                ],
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: AppColors.error,
                  ),
                  onPressed: onDelete,
                  tooltip: 'Remove',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final suffix = dt.hour < 12 ? 'AM' : 'PM';
    return '${dt.day}/${dt.month}  $h:${dt.minute.toString().padLeft(2, '0')} $suffix';
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _EmptyMedications extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyMedications({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.medication_outlined,
              size: 80,
              color: AppColors.lightTextSecondary,
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'No Medications Added',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Keep track of your medications and never miss a dose.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              height: AppSpacing.buttonHeight,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Add First Medication'),
                onPressed: onAdd,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet for adding a medication
class _AddMedicationSheet extends StatefulWidget {
  const _AddMedicationSheet();

  @override
  State<_AddMedicationSheet> createState() => _AddMedicationSheetState();
}

class _AddMedicationSheetState extends State<_AddMedicationSheet> {
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  MedicationFrequency _frequency = MedicationFrequency.daily;
  final List<MedicationTime> _times = [
    const MedicationTime(hour: 8, minute: 0),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  void _addTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _times.add(MedicationTime(hour: picked.hour, minute: picked.minute));
      });
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    if (_times.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one time')),
      );
      return;
    }

    final med = MedicationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      dosage: _dosageController.text.trim(),
      frequency: _frequency,
      times: _times,
      instructions: _instructionsController.text.trim().isNotEmpty
          ? _instructionsController.text.trim()
          : null,
    );

    context.read<MedicationProvider>().addMedication(med);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Add Medication',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.lg),

              TextFormField(
                controller: _nameController,
                decoration: _inputDeco('Medication Name', Icons.medication),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: AppSpacing.md),

              TextFormField(
                controller: _dosageController,
                decoration: _inputDeco('Dosage (e.g. 500mg)', Icons.science),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: AppSpacing.md),

              TextFormField(
                controller: _instructionsController,
                decoration: _inputDeco('Instructions (optional)', Icons.notes),
                maxLines: 2,
              ),
              const SizedBox(height: AppSpacing.md),

              /// Frequency
              DropdownButtonFormField<MedicationFrequency>(
                initialValue: _frequency,
                decoration: _inputDeco('Frequency', Icons.repeat),
                items: MedicationFrequency.values
                    .map(
                      (f) => DropdownMenuItem(
                        value: f,
                        child: Text(_frequencyLabel(f)),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _frequency = v);
                },
              ),
              const SizedBox(height: AppSpacing.md),

              /// Times
              Row(
                children: [
                  const Text(
                    'Reminder Times:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Add Time'),
                    onPressed: _addTime,
                  ),
                ],
              ),
              Wrap(
                spacing: 8,
                children: _times
                    .map(
                      (t) => Chip(
                        label: Text(t.formatted),
                        onDeleted: () {
                          setState(() => _times.remove(t));
                        },
                      ),
                    )
                    .toList(),
              ),

              const SizedBox(height: AppSpacing.xl),

              SizedBox(
                width: double.infinity,
                height: AppSpacing.buttonHeight,
                child: ElevatedButton(
                  onPressed: _save,
                  child: const Text(
                    'Save Medication',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      filled: true,
    );
  }

  String _frequencyLabel(MedicationFrequency f) {
    switch (f) {
      case MedicationFrequency.daily:
        return 'Once Daily';
      case MedicationFrequency.twiceDaily:
        return 'Twice Daily';
      case MedicationFrequency.threeTimesDaily:
        return 'Three Times Daily';
      case MedicationFrequency.weekly:
        return 'Weekly';
      case MedicationFrequency.asNeeded:
        return 'As Needed';
    }
  }
}
