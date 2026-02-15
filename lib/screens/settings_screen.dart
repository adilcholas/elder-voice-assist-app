import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/role_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final roleProvider = Provider.of<RoleProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            /// Current Role Card
            Card(
              child: ListTile(
                leading: const Icon(Icons.person),
                title: const Text("Current Role"),
                subtitle: Text(
                  roleProvider.isElder
                      ? "Elder"
                      : roleProvider.isCaregiver
                          ? "Caregiver"
                          : "Not Selected",
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// Change Role
            ListTile(
              leading: const Icon(Icons.switch_account),
              title: const Text("Change Role"),
              onTap: () {
                roleProvider.clearRole();
                context.go('/role-selection');
              },
            ),

            /// Language (Future PRD feature)
            ListTile(
              leading: const Icon(Icons.language),
              title: const Text("Language"),
              subtitle: const Text("English (Default)"),
              onTap: () {},
            ),

            /// Notifications
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text("Alert Preferences"),
              onTap: () {},
            ),

            const Spacer(),

            const Text(
              "ElderVoiceAssist v1.0",
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
