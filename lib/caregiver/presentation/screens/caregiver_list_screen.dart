import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sozotap/caregiver/providers/caregiver_providers.dart';
import 'package:sozotap/caregiver/domain/models/caregiver_relationship_model.dart';

class CaregiverListScreen extends ConsumerWidget {
  const CaregiverListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final caregiversAsync = ref.watch(caregiversStreamProvider);
    final repo = ref.watch(caregiverRepositoryProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1C1E),
        title: const Text('Caregiver Access & Grants', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: caregiversAsync.when(
        data: (caregivers) {
          if (caregivers.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(color: Color(0xFF1C1C1E), shape: BoxShape.circle),
                      child: const Icon(Icons.family_restroom_rounded, size: 48, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    const Text('No Caregivers Invited', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text(
                      'Grant trusted family members or medical caregivers access to receive live SOS alerts and view emergency medical summaries.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0A84FF),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => context.push('/caregivers/invite'),
                      icon: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white),
                      label: const Text('Invite Caregiver', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('ACTIVE & PENDING CAREGIVERS', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                  TextButton.icon(
                    onPressed: () => context.push('/caregivers/invite'),
                    icon: const Icon(Icons.add, color: Color(0xFF0A84FF), size: 18),
                    label: const Text('Invite Caregiver', style: TextStyle(color: Color(0xFF0A84FF), fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...caregivers.map((rel) => _buildCaregiverTile(context, ref, rel)),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF0A84FF))),
        error: (err, _) => Center(child: Text('Error loading caregivers: $err', style: const TextStyle(color: Colors.red))),
      ),
    );
  }

  Widget _buildCaregiverTile(BuildContext context, WidgetRef ref, CaregiverRelationship rel) {
    final repo = ref.watch(caregiverRepositoryProvider);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: const Color(0xFF1C1C1E), borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF30D158).withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.shield_outlined, color: Color(0xFF30D158), size: 20),
        ),
        title: Text(rel.caregiverUserId, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Text(
          'Role: ${rel.role} • Status: ${rel.invitationStatus.name.toUpperCase()}\nPermissions: SOS Alerts, Live Location',
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.remove_circle_outline, color: Color(0xFFFF3B30)),
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: const Color(0xFF1C1C1E),
                title: const Text('Revoke Caregiver Access?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                content: Text('Revoking access for "${rel.caregiverUserId}" will immediately stop live emergency updates for this user.', style: const TextStyle(color: Colors.grey)),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF3B30)),
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Revoke Access', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );

            if (confirm == true) {
              await repo.revokeCaregiver(rel.relationshipId);
            }
          },
        ),
      ),
    );
  }
}
