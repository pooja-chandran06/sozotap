import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../constants/app_colors.dart';
import '../models/medical_profile.dart';
import '../providers/medical_profile_provider.dart';

class EmergencyConsentSettingsScreen extends ConsumerStatefulWidget {
  const EmergencyConsentSettingsScreen({super.key});

  @override
  ConsumerState<EmergencyConsentSettingsScreen> createState() => _EmergencyConsentSettingsScreenState();
}

class _EmergencyConsentSettingsScreenState extends ConsumerState<EmergencyConsentSettingsScreen> {
  bool _isSaving = false;

  Future<void> _updateConsentField(String fieldName, bool newValue) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);

    try {
      await FirebaseFirestore.instance.collection('medical_profiles').doc(user.uid).set({
        fieldName: newValue,
        'lastEmergencyProfileUpdateAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Privacy consent settings updated.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update consent settings: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(medicalProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Emergency Visibility Consent',
          style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: profileAsync.when(
        data: (profile) {
          final MedicalProfile currentProfile = profile ??
              MedicalProfile(
                uid: FirebaseAuth.instance.currentUser?.uid ?? '',
                fullName: 'User',
                age: 0,
                gender: '',
                bloodGroup: '',
                heightCm: 0,
                weightKg: 0,
                medicalConditions: '',
                allergies: '',
                currentMedications: '',
                pastSurgeries: '',
                implants: '',
                isPregnant: false,
                isOrganDonor: false,
                insuranceInfo: '',
                primaryDoctor: '',
                preferredHospital: '',
                notes: '',
              );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Emergency Disclosure Controls',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Specify which medical details are accessible when a responder scans your QR code or when an SOS is active.',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary, fontFamily: 'Poppins'),
                ),
                const SizedBox(height: 24),

                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    children: [
                      SwitchListTile.adaptive(
                        title: const Text('Enable Emergency QR Lookup', style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: const Text('Allow responders to lookup emergency info via QR key.'),
                        value: currentProfile.emergencyAccessEnabled,
                        activeColor: AppColors.primary,
                        onChanged: _isSaving
                            ? null
                            : (val) => _updateConsentField('emergencyAccessEnabled', val),
                      ),
                      const Divider(height: 1),
                      SwitchListTile.adaptive(
                        title: const Text('Share Full Name'),
                        subtitle: const Text('Displays your name on emergency responder screen.'),
                        value: currentProfile.shareNameInEmergency,
                        activeColor: AppColors.primary,
                        onChanged: _isSaving
                            ? null
                            : (val) => _updateConsentField('shareNameInEmergency', val),
                      ),
                      const Divider(height: 1),
                      SwitchListTile.adaptive(
                        title: const Text('Share Profile Photo'),
                        subtitle: const Text('Displays your photo for responder identity verification.'),
                        value: currentProfile.sharePhotoInEmergency,
                        activeColor: AppColors.primary,
                        onChanged: _isSaving
                            ? null
                            : (val) => _updateConsentField('sharePhotoInEmergency', val),
                      ),
                      const Divider(height: 1),
                      SwitchListTile.adaptive(
                        title: const Text('Share Doctor & Preferred Hospital'),
                        subtitle: const Text('Displays primary physician and preferred hospital.'),
                        value: currentProfile.shareDoctorHospitalInEmergency,
                        activeColor: AppColors.primary,
                        onChanged: _isSaving
                            ? null
                            : (val) => _updateConsentField('shareDoctorHospitalInEmergency', val),
                      ),
                      const Divider(height: 1),
                      SwitchListTile.adaptive(
                        title: const Text('Share Emergency Contacts'),
                        subtitle: const Text('Allows responders to call your emergency contacts directly.'),
                        value: currentProfile.shareContactsInEmergency,
                        activeColor: AppColors.primary,
                        onChanged: _isSaving
                            ? null
                            : (val) => _updateConsentField('shareContactsInEmergency', val),
                      ),
                      const Divider(height: 1),
                      SwitchListTile.adaptive(
                        title: const Text('Share Hospital Navigation Directions'),
                        subtitle: const Text('Displays map navigation link to preferred hospital.'),
                        value: currentProfile.shareDirectionsInEmergency,
                        activeColor: AppColors.primary,
                        onChanged: _isSaving
                            ? null
                            : (val) => _updateConsentField('shareDirectionsInEmergency', val),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading consent options: $err')),
      ),
    );
  }
}
