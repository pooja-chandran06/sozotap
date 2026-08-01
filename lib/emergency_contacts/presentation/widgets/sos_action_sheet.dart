import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../constants/app_colors.dart';
import '../../../core/sos/sos_orchestrator.dart';
import '../../../core/sos/sos_logger.dart';
import '../../../core/sos/firestore_sms_dispatch_service.dart';
import '../../../core/sos/firestore_email_dispatch_service.dart';
import '../../../core/sos/firestore_push_dispatch_service.dart';
import '../../../core/sos/dispatch_service.dart';
import '../../../core/templates/template_service.dart';
import '../../domain/models/emergency_contact.dart';
import '../../../medical_profile/presentation/providers/medical_profile_provider.dart';
import '../providers/emergency_contacts_provider.dart';
import 'sos_status_widget.dart';

class SosActionSheet extends ConsumerStatefulWidget {
  const SosActionSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const SosActionSheet(),
    );
  }

  @override
  ConsumerState<SosActionSheet> createState() => _SosActionSheetState();
}

class _SosActionSheetState extends ConsumerState<SosActionSheet> {
  List<String> _dispatchedMessageIds = [];
  bool _isDispatched = false;
  bool _isInvoking = false;

  @override
  Widget build(BuildContext context) {
    final contactsState = ref.watch(emergencyContactsProvider);
    final profileState = ref.watch(medicalProfileProvider);

    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'EMERGENCY SOS',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.primary, fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
          ),
          const SizedBox(height: 16),
          
          if (!_isDispatched) ...[
            const Text(
              'Activating SOS will immediately send your medical profile and location to your emergency contacts via SMS and Email.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 24),
            if (contactsState.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (contactsState.contacts.isEmpty)
              const Text('No emergency contacts available. Please add them in settings.', textAlign: TextAlign.center)
            else
              ...contactsState.contacts.take(3).map((c) => _buildContactRow(c)).toList(),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isInvoking ? null : () async {
                final profile = profileState.value;
                if (profile == null) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Medical profile not found.')));
                  return;
                }

                setState(() => _isInvoking = true);

                final orchestrator = SosOrchestrator(
                  TemplateService(),
                  SosLogger(),
                  FirestoreSmsDispatchService(),
                  FirestoreEmailDispatchService(),
                  FirestorePushDispatchService(),
                );
                
                final ids = await orchestrator.triggerSos(
                  profile: profile,
                  contacts: contactsState.contacts,
                  channel: NotificationChannel.all,
                  dynamicVars: {
                    'timestamp': DateTime.now().toIso8601String(),
                    'gpsLatitude': 37.7749, // Stub: In real app, fetch from location package
                    'gpsLongitude': -122.4194,
                    'sosId': 'sos_${DateTime.now().millisecondsSinceEpoch}',
                  }
                );
                
                if (mounted) {
                  setState(() {
                    _dispatchedMessageIds = ids;
                    _isDispatched = true;
                    _isInvoking = false;
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isInvoking 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('INVOKE SOS NOW', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            ),
          ] else ...[
            SosStatusWidget(messageIds: _dispatchedMessageIds),
          ],
          
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_isDispatched ? 'Close' : 'Cancel', style: const TextStyle(color: Colors.grey, fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildContactRow(EmergencyContact contact) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(contact.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(contact.phoneNumber, style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          Row(
            children: [
              if (contact.canCall) const Icon(Icons.phone, color: Colors.green, size: 28),
              const SizedBox(width: 16),
              if (contact.canSms) const Icon(Icons.message, color: Colors.blue, size: 28),
            ],
          )
        ],
      ),
    );
  }
}
