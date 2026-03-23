import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/user_role.dart';
import '../providers/role_provider.dart';
import '../utils/app_colors.dart';
import '../utils/app_spacing.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _selectRole(UserRole role) async {
    if (!_formKey.currentState!.validate()) return;

    final roleProvider = context.read<RoleProvider>();
    await roleProvider.setRole(role, name: _nameController.text.trim());

    if (!mounted) return;
    if (role == UserRole.elder) {
      context.go('/elder/home');
    } else {
      context.go('/caregiver/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                /// App Logo / Icon
                const Icon(
                  Icons.health_and_safety,
                  size: 80,
                  color: AppColors.primary,
                ),
                const SizedBox(height: AppSpacing.md),

                const Text(
                  'Aura',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const Text(
                  'Elder Voice Assist',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    color: AppColors.lightTextSecondary,
                  ),
                ),

                const SizedBox(height: AppSpacing.xxl),

                /// Name input
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Your Name',
                    hintText: 'Enter your name',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    filled: true,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: AppSpacing.xl),

                const Text(
                  'I am a...',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),

                const SizedBox(height: AppSpacing.lg),

                /// Elder Button
                SizedBox(
                  height: 70,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.elderly, size: 28),
                    label: const Text('Elder', style: TextStyle(fontSize: 22)),
                    onPressed: () => _selectRole(UserRole.elder),
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                /// Caregiver Button
                SizedBox(
                  height: 70,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.medical_services_outlined, size: 28),
                    label: const Text(
                      'Caregiver',
                      style: TextStyle(fontSize: 22),
                    ),
                    onPressed: () => _selectRole(UserRole.caregiver),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
