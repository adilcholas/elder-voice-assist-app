import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ElderHomeScreen extends StatelessWidget {
  const ElderHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Home"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "How can I help you today?",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),

            /// Voice Button (Core Feature)
            ElevatedButton(
              onPressed: () {
                // GoRouter navigation (NOT Navigator)
                context.go('/elder/voice');
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(30),
                shape: const CircleBorder(),
              ),
              child: const Icon(Icons.mic, size: 50),
            ),

            const SizedBox(height: 30),

            /// Settings Button
            ElevatedButton(
              onPressed: () {
                // GoRouter navigation
                context.go('/settings');
              },
              child: const Text("Settings"),
            ),
          ],
        ),
      ),
    );
  }
}
