import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/alert_model.dart';
import '../widgets/alert_card.dart';

class CaregiverDashboardScreen extends StatelessWidget {
  const CaregiverDashboardScreen({super.key});

  // Mock alerts (replace with provider + Firebase later)
  List<AlertModel> get mockAlerts => [
        AlertModel(
          id: '1',
          elderName: 'John Mathew',
          alertType: 'Emergency Voice Alert',
          timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
          location: 'Kochi, Kerala',
          isActive: true,
        ),
        AlertModel(
          id: '2',
          elderName: 'Mary Joseph',
          alertType: 'Medication Reminder Missed',
          timestamp: DateTime.now().subtract(const Duration(hours: 1)),
          location: 'Ernakulam',
          isActive: false,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Caregiver Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              context.go('/settings');
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// Status Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Connected Elders",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text("Monitoring real-time alerts and activity"),
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// Alerts Section Title
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Active Alerts",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 10),

            /// Alert List
            Expanded(
              child: ListView.builder(
                itemCount: mockAlerts.length,
                itemBuilder: (context, index) {
                  final alert = mockAlerts[index];
                  return AlertCard(
                    alert: alert,
                    onTap: () {
                      context.go(
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
}
