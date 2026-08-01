import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/emergency_contact.dart';
import '../providers/emergency_contacts_provider.dart';
import '../../../constants/app_colors.dart';

class EmergencyContactTile extends ConsumerWidget {
  final EmergencyContact contact;

  const EmergencyContactTile({super.key, required this.contact});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withOpacity(0.1),
          foregroundColor: AppColors.primary,
          child: Text(contact.name.isNotEmpty ? contact.name[0].toUpperCase() : '?'),
        ),
        title: Text(contact.name, style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
        subtitle: Text('${contact.relationship.name.toUpperCase()} • ${contact.phoneNumber}'),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'delete') {
              ref.read(emergencyContactsProvider.notifier).delete(contact.id);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'delete',
              child: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }
}
