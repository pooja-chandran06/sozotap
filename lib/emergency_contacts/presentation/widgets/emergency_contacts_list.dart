import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/emergency_contacts_provider.dart';
import 'emergency_contact_tile.dart';

class EmergencyContactsList extends ConsumerWidget {
  const EmergencyContactsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(emergencyContactsProvider);

    if (state.isLoading && state.contacts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.contacts.isEmpty) {
      return Center(
        child: Text(
          'Error: ${state.error}',
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    if (state.contacts.isEmpty) {
      return const Center(
        child: Text(
          'No emergency contacts added yet.\nTap the + button to add one.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(emergencyContactsProvider.notifier).loadContacts(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: state.contacts.length,
        itemBuilder: (context, index) {
          final contact = state.contacts[index];
          return EmergencyContactTile(contact: contact);
        },
      ),
    );
  }
}
