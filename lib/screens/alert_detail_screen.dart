
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/alert_model.dart';

class AlertDetailScreen extends StatelessWidget {
  const AlertDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final alert = GoRouterState.of(context).extra as AlertModel?;

    if (alert == null) {
      return const Scaffold(
        body: Center(child: Text("No Alert Data")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Alert Details"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Alert Status
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                alert.alertType,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ),

            const SizedBox(height: 24),

            /// Elder Name
            _infoTile("Elder Name", alert.elderName),

            /// Location
            _infoTile("Location", alert.location),

            /// Time
            _infoTile(
              "Time",
              alert.timestamp.toString(),
            ),

            const Spacer(),

            /// Action Buttons (High Priority UI)
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.call),
                label: const Text(
                  "Call Elder",
                  style: TextStyle(fontSize: 18),
                ),
                onPressed: () {
                  // Integrate call functionality later
                },
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              height: 60,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.warning),
                label: const Text(
                  "Escalate Emergency",
                  style: TextStyle(fontSize: 18),
                ),
                onPressed: () {},
              ),
            ),

            const SizedBox(height: 12),

            TextButton(
              onPressed: () => context.pop(),
              child: const Text("Back"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoTile(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
