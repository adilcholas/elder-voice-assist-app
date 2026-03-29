import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/contact_model.dart';
import '../providers/contact_provider.dart';
import '../utils/app_colors.dart';
import '../utils/app_spacing.dart';
import '../utils/app_typography.dart';

class ContactsScreen extends StatelessWidget {
  const ContactsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final contactProvider = context.watch<ContactProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Contacts'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: contactProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : contactProvider.errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 60, color: AppColors.error),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          contactProvider.errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.error),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        ElevatedButton(
                          onPressed: () {
                             // Try to reload, but we need the RoleProvider to do it from the top
                          },
                          child: const Text('Try Again'),
                        ),
                      ],
                    ),
                  ),
                )
              : contactProvider.contacts.isEmpty
                  ? _EmptyContacts(onAdd: () => _showAddContactSheet(context))
                  : ListView.separated(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      itemCount: contactProvider.contacts.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        final contact = contactProvider.contacts[index];
                        return _ContactCard(
                          contact: contact,
                          onCall: () => _callContact(context, contact),
                          onDelete: () =>
                              _confirmDelete(context, contactProvider, contact),
                        );
                      },
                    ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddContactSheet(context),
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Add Contact', style: TextStyle(fontSize: 16)),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Future<void> _callContact(
      BuildContext context, ContactModel contact) async {
    final uri = Uri.parse('tel:${contact.phone}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cannot call ${contact.name}. Check the number.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    ContactProvider provider,
    ContactModel contact,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Contact?'),
        content: Text('Remove ${contact.name} from your contacts?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await provider.removeContact(contact.id);
    }
  }

  void _showAddContactSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _AddContactSheet(),
    );
  }
}

// ─────────────────────────────────────────────
// Contact Card Widget
// ─────────────────────────────────────────────

class _ContactCard extends StatelessWidget {
  final ContactModel contact;
  final VoidCallback onCall;
  final VoidCallback onDelete;

  const _ContactCard({
    required this.contact,
    required this.onCall,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = _relationshipColor(contact.relationship);

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: color.withValues(alpha: 0.35)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.md),
        child: Row(
          children: [
            // Avatar with initial
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  contact.name.isNotEmpty
                      ? contact.name[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ),

            const SizedBox(width: AppSpacing.md),

            // Name + relationship badge + phone
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(contact.name, style: AppTypography.title),
                  const SizedBox(height: 2),
                  _RelationshipBadge(
                    label: _capitalize(contact.relationship),
                    color: color,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    contact.phone,
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Call button
            IconButton(
              icon: const Icon(Icons.phone_rounded, size: 30),
              color: AppColors.success,
              onPressed: onCall,
              tooltip: 'Call ${contact.name}',
            ),

            // Delete button
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 26),
              color: AppColors.error.withValues(alpha: 0.7),
              onPressed: onDelete,
              tooltip: 'Remove',
            ),
          ],
        ),
      ),
    );
  }

  Color _relationshipColor(String rel) {
    switch (rel.toLowerCase()) {
      case 'son':
      case 'daughter':
      case 'child':
        return AppColors.primary;
      case 'doctor':
      case 'nurse':
        return AppColors.success;
      case 'friend':
        return AppColors.secondary;
      case 'caregiver':
        return Colors.deepPurple;
      default:
        return Colors.blueGrey;
    }
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

class _RelationshipBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _RelationshipBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Empty State
// ─────────────────────────────────────────────

class _EmptyContacts extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyContacts({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.contacts_outlined,
              size: 80,
              color: AppColors.lightTextSecondary,
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'No Contacts Yet',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add contacts so you can call them\nby saying their name.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 17),
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              height: AppSpacing.buttonHeight,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.person_add_alt_1),
                label: const Text(
                  'Add First Contact',
                  style: TextStyle(fontSize: 18),
                ),
                onPressed: onAdd,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Add Contact Bottom Sheet
// ─────────────────────────────────────────────

class _AddContactSheet extends StatefulWidget {
  const _AddContactSheet();

  @override
  State<_AddContactSheet> createState() => _AddContactSheetState();
}

class _AddContactSheetState extends State<_AddContactSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String _relationship = 'son';

  static const _relationships = [
    'son',
    'daughter',
    'caregiver',
    'doctor',
    'friend',
    'other',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final contact = ContactModel(
      id: '',
      name: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      relationship: _relationship,
    );

    context.read<ContactProvider>().addContact(contact);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add Contact',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.lg),

            TextFormField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: _deco('Full Name', Icons.person_outline),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Name is required' : null,
            ),
            const SizedBox(height: AppSpacing.md),

            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: _deco('Phone Number', Icons.phone_outlined),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Phone is required';
                if (v.trim().length < 7) return 'Enter a valid phone number';
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),

            DropdownButtonFormField<String>(
              initialValue: _relationship,
              decoration: _deco('Relationship', Icons.people_outline),
              items: _relationships
                  .map(
                    (r) => DropdownMenuItem(
                      value: r,
                      child: Text(
                        r[0].toUpperCase() + r.substring(1),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _relationship = v);
              },
            ),

            const SizedBox(height: AppSpacing.xl),

            SizedBox(
              width: double.infinity,
              height: AppSpacing.buttonHeight,
              child: ElevatedButton(
                onPressed: _save,
                child: const Text(
                  'Save Contact',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _deco(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      filled: true,
    );
  }
}
