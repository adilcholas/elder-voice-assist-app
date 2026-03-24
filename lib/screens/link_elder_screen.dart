import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/role_provider.dart';
import '../utils/app_colors.dart';
import '../utils/app_spacing.dart';

class LinkElderScreen extends StatefulWidget {
  const LinkElderScreen({super.key});

  @override
  State<LinkElderScreen> createState() => _LinkElderScreenState();
}

class _LinkElderScreenState extends State<LinkElderScreen> {
  final _codeController = TextEditingController();
  
  Future<void> _link() async {
    if (_codeController.text.trim().isEmpty) return;
    final success = await context.read<RoleProvider>().linkElder(_codeController.text.trim());
    if (mounted) {
      if (success) {
        context.go('/caregiver/dashboard');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid invite code or elder not found.')),
        );
      }
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<RoleProvider>().isLoading;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Link with Elder'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<RoleProvider>().logout();
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.supervisor_account, size: 80, color: AppColors.primary),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              'Enter the 6-character Invite Code provided by the Elder to link your accounts.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: AppSpacing.xl),
            TextField(
              controller: _codeController,
              decoration: const InputDecoration(
                labelText: 'Invite Code',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton(
              onPressed: isLoading ? null : _link,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
              child: isLoading 
               ? const CircularProgressIndicator()
               : const Text('Link Account', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}
