import 'package:flutter/material.dart';

class EmergencyAlertScreen extends StatelessWidget {
  const EmergencyAlertScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red.shade50,
      appBar: AppBar(title: const Text("Emergency Alert")),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.warning, color: Colors.red, size: 100),
            SizedBox(height: 20),
            Text(
              "Emergency Alert Sent!",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
