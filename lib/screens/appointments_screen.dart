import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/appointment_provider.dart';
import '../models/appointment_model.dart';
import '../utils/app_colors.dart';
import '../utils/app_spacing.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {

  Future<void> _showAddDialog() async {
    final titleCtrl = TextEditingController();
    final doctorCtrl = TextEditingController();
    final locationCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    DateTime? selectedDate = DateTime.now();
    TimeOfDay? selectedTime = TimeOfDay.now();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateBuilder) => AlertDialog(
          title: const Text('New Appointment'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Purpose (e.g. Checkup)')),
                TextField(controller: doctorCtrl, decoration: const InputDecoration(labelText: 'Doctor Name')),
                TextField(controller: locationCtrl, decoration: const InputDecoration(labelText: 'Location')),
                TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'Notes (Optional)')),
                const SizedBox(height: 10),
                ListTile(
                  title: Text('Date: ${selectedDate!.toLocal().toString().split(' ')[0]}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate!,
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2030),
                    );
                    if (date != null) setStateBuilder(() => selectedDate = date);
                  },
                ),
                ListTile(
                  title: Text('Time: ${selectedTime!.format(context)}'),
                  trailing: const Icon(Icons.access_time),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: selectedTime!,
                    );
                    if (time != null) setStateBuilder(() => selectedTime = time);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (titleCtrl.text.isEmpty || doctorCtrl.text.isEmpty) return;
                final finalDateTime = DateTime(
                  selectedDate!.year, selectedDate!.month, selectedDate!.day,
                  selectedTime!.hour, selectedTime!.minute,
                );
                final apt = AppointmentModel(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  title: titleCtrl.text,
                  doctorName: doctorCtrl.text,
                  location: locationCtrl.text,
                  dateTime: finalDateTime,
                  notes: notesCtrl.text,
                );
                context.read<AppointmentProvider>().addAppointment(apt);
                Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppointmentProvider>();
    final upcomingApts = provider.appointments.where((a) => a.dateTime.isAfter(DateTime.now())).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Doctor Appointments')),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
      body: upcomingApts.isEmpty 
          ? const Center(child: Text('No upcoming appointments', style: TextStyle(fontSize: 18)))
          : ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: upcomingApts.length,
              itemBuilder: (context, index) {
                final apt = upcomingApts[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(AppSpacing.md),
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.primary,
                      radius: 24,
                      child: Icon(Icons.local_hospital, color: Colors.white),
                    ),
                    title: Text('${apt.title} with Dr. ${apt.doctorName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text('📅 ${apt.dateTime.toLocal().toString().replaceAll(':00.000', '')}'),
                        if (apt.location.isNotEmpty) Text('📍 ${apt.location}'),
                        const SizedBox(height: 4),
                        const Text('Long press to remove appointment'),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.calendar_month, color: AppColors.secondary, size: 28),
                      tooltip: 'Add to Device Calendar',
                      onPressed: () {
                        provider.addAppointmentToCalendar(apt);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Opening Calendar...')));
                      },
                    ),
                    onLongPress: () {
                      provider.removeAppointment(apt.id);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Appointment removed')));
                    },
                  ),
                );
              },
            ),
    );
  }
}
