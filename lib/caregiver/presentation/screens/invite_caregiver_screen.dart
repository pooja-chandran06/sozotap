import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sozotap/caregiver/providers/caregiver_providers.dart';
import 'package:sozotap/caregiver/domain/models/caregiver_relationship_model.dart';

class InviteCaregiverScreen extends ConsumerStatefulWidget {
  const InviteCaregiverScreen({super.key});

  @override
  ConsumerState<InviteCaregiverScreen> createState() => _InviteCaregiverScreenState();
}

class _InviteCaregiverScreenState extends ConsumerState<InviteCaregiverScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  bool _viewEmergencySummary = true;
  bool _receiveSosAlerts = true;
  bool _viewActiveSosLocation = true;
  bool _manageEmergencyContacts = false;
  bool _isSubmitting = false;

  Future<void> _sendInvitation() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final repo = ref.read(caregiverRepositoryProvider);
      final permissions = CaregiverPermissions(
        viewEmergencySummary: _viewEmergencySummary,
        receiveSosAlerts: _receiveSosAlerts,
        viewActiveSosLocation: _viewActiveSosLocation,
        manageEmergencyContacts: _manageEmergencyContacts,
      );

      await repo.inviteCaregiver(_emailController.text.trim(), permissions);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(backgroundColor: Colors.green, content: Text('Caregiver invitation sent successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.red, content: Text('Failed to invite caregiver: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1C1E),
        title: const Text('Invite Caregiver', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('CAREGIVER IDENTIFIER', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Registered Caregiver Email',
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFF1C1C1E),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF0A84FF)),
              ),
              validator: (val) {
                if (val == null || val.isEmpty || !val.contains('@')) {
                  return 'Please enter a valid email address';
                }
                return null;
              },
            ),

            const SizedBox(height: 24),
            const Text('GRANULAR CAREGIVER PERMISSIONS', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            Container(
              decoration: BoxDecoration(color: const Color(0xFF1C1C1E), borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  SwitchListTile(
                    activeColor: const Color(0xFF0A84FF),
                    title: const Text('View Emergency Medical Summary', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Allows viewing blood group, allergies & medical notes during SOS', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    value: _viewEmergencySummary,
                    onChanged: (val) => setState(() => _viewEmergencySummary = val),
                  ),
                  const Divider(color: Colors.white12, height: 1),
                  SwitchListTile(
                    activeColor: const Color(0xFF0A84FF),
                    title: const Text('Receive Emergency SOS Alerts', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Dispatches push & SMS alerts when SOS countdown finishes', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    value: _receiveSosAlerts,
                    onChanged: (val) => setState(() => _receiveSosAlerts = val),
                  ),
                  const Divider(color: Colors.white12, height: 1),
                  SwitchListTile(
                    activeColor: const Color(0xFF0A84FF),
                    title: const Text('View Active Live GPS Location', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Displays real-time map location during active SOS alerts', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    value: _viewActiveSosLocation,
                    onChanged: (val) => setState(() => _viewActiveSosLocation = val),
                  ),
                  const Divider(color: Colors.white12, height: 1),
                  SwitchListTile(
                    activeColor: const Color(0xFF0A84FF),
                    title: const Text('Manage Emergency Contacts', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Grants permission to edit or add emergency contacts list', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    value: _manageEmergencyContacts,
                    onChanged: (val) => setState(() => _manageEmergencyContacts = val),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A84FF),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isSubmitting ? null : _sendInvitation,
                icon: _isSubmitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.send_rounded, color: Colors.white),
                label: const Text('Send Caregiver Invitation', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
