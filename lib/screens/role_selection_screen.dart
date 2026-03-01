import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/user_role.dart';
import '../providers/role_provider.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final roleProvider = Provider.of<RoleProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(title: const Text("Select Role"), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Who are you?",
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 50),

            /// Elder Button (FIXED)
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: () {
                  roleProvider.setRole(UserRole.elder);

                  // ✅ Correct GoRouter navigation
                  context.go('/elder/home');
                },
                child: const Text("Elder", style: TextStyle(fontSize: 20)),
              ),
            ),

            const SizedBox(height: 20),

            /// Caregiver Button (Already correct)
            SizedBox(
              width: double.infinity,
              height: 60,
              child: OutlinedButton(
                onPressed: () {
                  roleProvider.setRole(UserRole.caregiver);

                  // ✅ Correct GoRouter navigation
                  context.go('/caregiver/dashboard');
                },
                child: const Text("Caregiver", style: TextStyle(fontSize: 20)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
