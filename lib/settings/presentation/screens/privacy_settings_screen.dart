import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/settings_providers.dart';
import '../../domain/models/privacy_settings_model.dart';

class PrivacySettingsScreen extends ConsumerWidget {
  const PrivacySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final privacyAsync = ref.watch(privacySettingsStreamProvider);
    final repository = ref.watch(settingsRepositoryProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1C1E),
        title: const Text('Privacy & Emergency Sharing', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.restore, color: Color(0xFF0A84FF)),
            tooltip: 'Reset to Recommended',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: const Color(0xFF1C1C1E),
                  title: const Text('Reset to Recommended Presets?', style: TextStyle(color: Colors.white)),
                  content: const Text(
                    'This will reset all emergency sharing flags to the recommended medical safety baseline.',
                    style: TextStyle(color: Colors.grey),
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0A84FF)),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Reset', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await repository.resetPrivacyToRecommended();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Privacy settings reset to recommended defaults.')),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: privacyAsync.when(
        data: (settings) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Master Emergency Access Switch
              Container(
                decoration: BoxDecoration(
                  color: settings.emergencyAccessEnabled
                      ? const Color(0xFF0A84FF).withOpacity(0.15)
                      : const Color(0xFFFF3B30).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: settings.emergencyAccessEnabled ? const Color(0xFF0A84FF) : const Color(0xFFFF3B30),
                  ),
                ),
                child: SwitchListTile(
                  activeColor: const Color(0xFF0A84FF),
                  title: const Text(
                    'Master Emergency Access',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Text(
                    settings.emergencyAccessEnabled
                        ? 'First responders can scan your QR code to view consented medical details during an emergency.'
                        : 'DISABLED: Public QR code scans will return an offline/unavailable response.',
                    style: TextStyle(
                      color: settings.emergencyAccessEnabled ? Colors.grey[300] : const Color(0xFFFF3B30),
                      fontSize: 13,
                    ),
                  ),
                  value: settings.emergencyAccessEnabled,
                  onChanged: (val) {
                    repository.updatePrivacySettings(settings.copyWith(emergencyAccessEnabled: val));
                  },
                ),
              ),

              const SizedBox(height: 24),
              const Text('PUBLIC MEDICAL CARD CONSENT FLAGS', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),

              _buildPrivacyTile(
                title: 'Share Full Name',
                explanation: 'Displays your full legal name on the public emergency web card when scanned by paramedics.',
                value: settings.shareNameInEmergency,
                onChanged: (val) => repository.updatePrivacySettings(settings.copyWith(shareNameInEmergency: val)),
              ),

              _buildPrivacyTile(
                title: 'Share Profile Photo',
                explanation: 'Allows paramedics to visually confirm identity using your uploaded profile photo.',
                value: settings.sharePhotoInEmergency,
                onChanged: (val) => repository.updatePrivacySettings(settings.copyWith(sharePhotoInEmergency: val)),
              ),

              _buildPrivacyTile(
                title: 'Share Blood Group',
                explanation: 'Crucial for emergency blood transfusions (e.g. O Negative, A Positive).',
                value: settings.shareBloodGroupInEmergency,
                onChanged: (val) => repository.updatePrivacySettings(settings.copyWith(shareBloodGroupInEmergency: val)),
              ),

              _buildPrivacyTile(
                title: 'Share Critical Allergies',
                explanation: 'Warns first responders of life-threatening drug/food allergies (Penicillin, Latex, Latex).',
                value: settings.shareAllergiesInEmergency,
                onChanged: (val) => repository.updatePrivacySettings(settings.copyWith(shareAllergiesInEmergency: val)),
              ),

              _buildPrivacyTile(
                title: 'Share Medical Conditions',
                explanation: 'Exposes chronic conditions (Diabetes, Epilepsy, Cardiac Pacemaker) needed for triage.',
                value: settings.shareMedicalConditionsInEmergency,
                onChanged: (val) => repository.updatePrivacySettings(settings.copyWith(shareMedicalConditionsInEmergency: val)),
              ),

              _buildPrivacyTile(
                title: 'Share Current Medications',
                explanation: 'Helps emergency physicians avoid severe drug-drug interactions.',
                value: settings.shareMedicationsInEmergency,
                onChanged: (val) => repository.updatePrivacySettings(settings.copyWith(shareMedicationsInEmergency: val)),
              ),

              _buildPrivacyTile(
                title: 'Share Medical Implants',
                explanation: 'Warns of metal implants or pacemakers before MRI or defibrillator usage.',
                value: settings.shareImplantsInEmergency,
                onChanged: (val) => repository.updatePrivacySettings(settings.copyWith(shareImplantsInEmergency: val)),
              ),

              _buildPrivacyTile(
                title: 'Share Doctor & Hospital Info',
                explanation: 'Provides contact details for your primary doctor and preferred hospital.',
                value: settings.shareDoctorHospitalInEmergency,
                onChanged: (val) => repository.updatePrivacySettings(settings.copyWith(shareDoctorHospitalInEmergency: val)),
              ),

              _buildPrivacyTile(
                title: 'Share Emergency Contacts List',
                explanation: 'Displays priority phone numbers so first responders can contact your family.',
                value: settings.shareEmergencyContactsInEmergency,
                onChanged: (val) => repository.updatePrivacySettings(settings.copyWith(shareEmergencyContactsInEmergency: val)),
              ),

              _buildPrivacyTile(
                title: 'Share Hospital Address Directions',
                explanation: 'Allows paramedics to navigate directly to your preferred medical facility.',
                value: settings.shareHospitalDirectionsInEmergency,
                onChanged: (val) => repository.updatePrivacySettings(settings.copyWith(shareHospitalDirectionsInEmergency: val)),
              ),

              _buildPrivacyTile(
                title: 'Share Emergency Doctor Notes',
                explanation: 'Displays custom clinical instructions or advance directives.',
                value: settings.shareEmergencyNotesInEmergency,
                onChanged: (val) => repository.updatePrivacySettings(settings.copyWith(shareEmergencyNotesInEmergency: val)),
              ),

              const SizedBox(height: 24),
              const Text('DISPATCH & ALERTS PRIVACY', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),

              _buildPrivacyTile(
                title: 'QR Code Scan Notification Alert',
                explanation: 'Sends a push alert to your phone whenever your public emergency QR code is scanned.',
                value: settings.qrScanAlertEnabled,
                onChanged: (val) => repository.updatePrivacySettings(settings.copyWith(qrScanAlertEnabled: val)),
              ),

              _buildPrivacyTile(
                title: 'SOS Live GPS Location Sharing',
                explanation: 'Attaches real-time GPS coordinates to emergency notifications when SOS is activated.',
                value: settings.sosLiveLocationSharingEnabled,
                onChanged: (val) => repository.updatePrivacySettings(settings.copyWith(sosLiveLocationSharingEnabled: val)),
              ),

              const SizedBox(height: 24),
              ListTile(
                tileColor: const Color(0xFF1C1C1E),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                leading: const Icon(Icons.notifications_active_outlined, color: Color(0xFF0A84FF)),
                title: const Text('Notification Preferences', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: const Text('Configure Push and SMS dispatch preferences', style: TextStyle(color: Colors.grey, fontSize: 12)),
                trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
                onTap: () => context.push('/notification-settings'),
              ),
              const SizedBox(height: 12),
              ListTile(
                tileColor: const Color(0xFF1C1C1E),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                leading: const Icon(Icons.qr_code_2_rounded, color: Color(0xFF30D158)),
                title: const Text('My Emergency QR Status', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: const Text('View, regenerate, or revoke dynamic QR token', style: TextStyle(color: Colors.grey, fontSize: 12)),
                trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
                onTap: () => context.push('/my-emergency-qr'),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF0A84FF))),
        error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
      ),
    );
  }

  Widget _buildPrivacyTile({
    required String title,
    required String explanation,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            activeColor: const Color(0xFF0A84FF),
            title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
            value: value,
            onChanged: onChanged,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
            child: Text(
              explanation,
              style: const TextStyle(color: Colors.grey, fontSize: 12, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}
