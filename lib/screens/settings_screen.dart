import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../providers/role_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/alert_provider.dart';
import '../providers/background_listener_provider.dart';
import '../providers/contact_provider.dart';
import '../services/background_voice_service.dart';
import '../utils/app_spacing.dart';
import '../utils/app_typography.dart';
import '../utils/app_colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _caregiverPhoneController;

  @override
  void initState() {
    super.initState();
    final rp = context.read<RoleProvider>();
    _nameController = TextEditingController(text: rp.userName);
    _phoneController = TextEditingController(text: rp.userPhone);
    _caregiverPhoneController = TextEditingController(text: rp.caregiverPhone);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _caregiverPhoneController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    await context.read<RoleProvider>().updateProfile(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      caregiverPhone: _caregiverPhoneController.text.trim(),
    );
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile saved')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final roleProvider = context.watch<RoleProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final alertProvider = context.read<AlertProvider>();
    final bgListenerProvider = context.watch<BackgroundListenerProvider>();
    final contactProvider = context.watch<ContactProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text('App Preferences', style: AppTypography.heading),
          const SizedBox(height: AppSpacing.lg),

          /// CURRENT ROLE CARD
          _SettingsCard(
            child: ListTile(
              leading: const Icon(Icons.person_outline, size: 28),
              title: const Text(
                'Current Role',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                roleProvider.isElder
                    ? 'Elder Mode (Voice Assistance Enabled)'
                    : roleProvider.isCaregiver
                    ? 'Caregiver Mode (Monitoring Dashboard)'
                    : 'Not Selected',
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  roleProvider.isElder
                      ? 'ELDER'
                      : roleProvider.isCaregiver
                      ? 'CAREGIVER'
                      : 'NONE',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          /// PROFILE SECTION
          _SettingsCard(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.manage_accounts_outlined,
                        color: AppColors.primary,
                        size: 24,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Profile',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _profileField('Your Name', _nameController, Icons.person),
                  const SizedBox(height: AppSpacing.sm),
                  _profileField(
                    'Your Phone',
                    _phoneController,
                    Icons.phone,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _profileField(
                    roleProvider.isElder
                        ? 'Caregiver Phone'
                        : 'Emergency Contact Phone',
                    _caregiverPhoneController,
                    Icons.contact_phone,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveProfile,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 50),
                      ),
                      child: const Text('Save Profile'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          /// DARK THEME TOGGLE
          _SettingsCard(
            child: SwitchListTile(
              secondary: const Icon(Icons.dark_mode_outlined, size: 28),
              title: const Text(
                'Dark Theme',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Warm dark theme for better night visibility',
              ),
              value: themeProvider.isDarkMode,
              onChanged: (value) => themeProvider.toggleTheme(value),
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          /// BACKGROUND EMERGENCY LISTENING (only for elders)
          if (roleProvider.isElder)
            _SettingsCard(
              child: SwitchListTile(
                secondary: const Icon(Icons.mic_none_rounded, size: 28),
                title: const Text(
                  'Background Emergency Listening',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  "Detect 'Help' even when app is minimized",
                ),
                value: bgListenerProvider.isRunning,
                onChanged: (value) async {
                  final messenger = ScaffoldMessenger.of(context);
                  if (value) {
                    final micPermission = await Permission.microphone.request();
                    if (micPermission.isGranted) {
                      await BackgroundVoiceService.startService();
                      bgListenerProvider.startListening(alertProvider);
                    } else {
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Microphone permission is required for voice detection',
                          ),
                        ),
                      );
                    }
                  } else {
                    await BackgroundVoiceService.stopService();
                    bgListenerProvider.stopListening();
                  }
                },
              ),
            ),

          if (roleProvider.isElder) const SizedBox(height: AppSpacing.md),

          /// MANAGE CONTACTS (only for elders)
          if (roleProvider.isElder) ...[
            _SettingsCard(
              child: ListTile(
                leading: const Icon(Icons.contacts_rounded, size: 28),
                title: const Text(
                  'Manage Contacts',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  contactProvider.contacts.isEmpty
                      ? 'No contacts saved yet'
                      : '${contactProvider.contacts.length} contact${contactProvider.contacts.length == 1 ? '' : 's'} saved',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/elder/contacts'),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          /// INVITE CODE (only for elders)
          if (roleProvider.isElder && roleProvider.profile?.inviteCode != null) ...[
            _SettingsCard(
              child: ListTile(
                leading: const Icon(Icons.share, size: 28),
                title: const Text(
                  'Your Invite Code',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                subtitle: const Text('Share this code with your Caregiver to link accounts'),
                trailing: Text(
                  roleProvider.profile!.inviteCode,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 2.0),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          /// LINK ANOTHER ELDER (only for caregivers)
          if (roleProvider.isCaregiver) ...[
            _SettingsCard(
              child: ListTile(
                leading: const Icon(Icons.person_add_alt_1, size: 28),
                title: const Text(
                  'Link Another Elder',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                subtitle: const Text('Add an additional elder using their invite code'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  context.push('/caregiver/link');
                },
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          /// LOG OUT
          _SettingsCard(
            child: ListTile(
              leading: const Icon(Icons.logout, size: 28),
              title: const Text(
                'Log Out',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              subtitle: const Text('Sign out of your account'),
              onTap: () async {
                await roleProvider.logout();
                if (context.mounted) {
                  context.go('/login');
                }
              },
            ),
          ),
          _SettingsCard(
            child: ListTile(
              leading: const Icon(Icons.delete_outline, size: 28),
              title: const Text(
                'Clear Alert History',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              subtitle: const Text('Remove all stored emergency alerts'),
              onTap: () async {
                final messenger = ScaffoldMessenger.of(context);
                final confirmed = await _confirmDialog(
                  context,
                  'Clear all alerts?',
                  'This cannot be undone.',
                );
                if (confirmed == true) {
                  await alertProvider.clearAllAlerts();
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Alert history cleared')),
                  );
                }
              },
            ),
          ),

          const SizedBox(height: AppSpacing.xxl),

          /// APP INFO
          Center(
            child: Column(
              children: const [
                Text(
                  'Aura - Elder Voice Assist',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 4),
                Text(
                  'Version 1.0 • Safety Assistant',
                  style: TextStyle(
                    color: AppColors.lightTextSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileField(
    String label,
    TextEditingController controller,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
    );
  }

  Future<bool?> _confirmDialog(
    BuildContext context,
    String title,
    String message,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final Widget child;
  const _SettingsCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.secondary.withValues(alpha: 0.2),
        ),
      ),
      child: child,
    );
  }
}
