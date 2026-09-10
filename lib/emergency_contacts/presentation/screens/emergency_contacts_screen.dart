import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../constants/app_colors.dart';
import '../widgets/emergency_contacts_list.dart';
import '../widgets/sos_action_sheet.dart';
import 'add_edit_contact_screen.dart';

class EmergencyContactsScreen extends ConsumerWidget {
  const EmergencyContactsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Emergency Contacts',
          style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.sos_rounded, color: Colors.white, size: 28),
            tooltip: 'Trigger Emergency SOS',
            onPressed: () => SosActionSheet.show(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            color: AppColors.primary.withOpacity(0.08),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppColors.primary),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Contacts are sorted by priority level (Priority 1 contacts receive immediate alert priority during SOS).',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary, fontFamily: 'Poppins'),
                  ),
                ),
              ],
            ),
          ),
          const Expanded(
            child: EmergencyContactsList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddEditContactScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Contact', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
