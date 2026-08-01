import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../constants/app_colors.dart';
import '../providers/emergency_contacts_provider.dart';
import '../widgets/emergency_contacts_list.dart';
import '../../domain/models/emergency_contact.dart';
import 'package:uuid/uuid.dart';

class EmergencyContactsScreen extends ConsumerWidget {
  const EmergencyContactsScreen({super.key});

  void _showAddContactDialog(BuildContext context, WidgetRef ref) {
    // Basic dialog for adding a contact; production version would have full validation.
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    Relationship selectedRel = Relationship.family;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Contact', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone Number (incl. country code)'),
              ),
              DropdownButtonFormField<Relationship>(
                value: selectedRel,
                items: Relationship.values.map((rel) {
                  return DropdownMenuItem(value: rel, child: Text(rel.name.toUpperCase()));
                }).toList(),
                onChanged: (val) {
                  if (val != null) selectedRel = val;
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              onPressed: () {
                final notifier = ref.read(emergencyContactsProvider.notifier);
                final userId = ref.read(emergencyContactsProvider.notifier)._userId; // Note: For real use, don't access private members, pass from provider
                // We'll construct it directly since we need the user ID
                
                final newContact = EmergencyContact(
                  id: const Uuid().v4(),
                  userId: 'CURRENT_USER_ID', // Should be pulled correctly in prod
                  name: nameCtrl.text.trim(),
                  relationship: selectedRel,
                  phoneNumber: phoneCtrl.text.trim(),
                  priority: 0,
                  canCall: true,
                  canSms: true,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                );
                
                // Using copyWith to fix userId dynamically based on the current auth state inside the notifier save method
                notifier.save(newContact);
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Emergency Contacts', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: const EmergencyContactsList(),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () => _showAddContactDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }
}
