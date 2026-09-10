import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../config/app_config.dart';
import '../../../constants/app_colors.dart';
import '../domain/models/public_emergency_dto.dart';

class PublicEmergencyViewScreen extends StatelessWidget {
  final PublicEmergencyDto dto;

  const PublicEmergencyViewScreen({
    super.key,
    required this.dto,
  });

  Future<void> _makeCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  Future<void> _openHospitalDirections(String address) async {
    final Uri mapUri = Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}');
    if (await canLaunchUrl(mapUri)) {
      await launchUrl(mapUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'EMERGENCY MEDICAL INFO',
          style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins', color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Patient Header Card
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      backgroundImage: dto.photoUrl != null && dto.photoUrl!.isNotEmpty
                          ? NetworkImage(dto.photoUrl!)
                          : null,
                      child: dto.photoUrl == null || dto.photoUrl!.isEmpty
                          ? const Icon(Icons.person_rounded, size: 40, color: AppColors.primary)
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dto.fullName,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins',
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'ID: ${dto.displayEmergencyId}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Blood Group Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.opacity_rounded, color: Colors.white, size: 32),
                      SizedBox(width: 12),
                      Text(
                        'BLOOD GROUP',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                  Text(
                    dto.bloodGroup,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Critical Allergies Card
            _buildSectionCard(
              title: 'Critical Allergies',
              icon: Icons.warning_amber_rounded,
              iconColor: Colors.orange.shade800,
              content: dto.allergies,
            ),
            const SizedBox(height: 12),

            // Medical Conditions Card
            _buildSectionCard(
              title: 'Medical Conditions',
              icon: Icons.local_hospital_rounded,
              iconColor: AppColors.primary,
              content: dto.medicalConditions,
            ),
            const SizedBox(height: 12),

            // Current Medications Card
            _buildSectionCard(
              title: 'Current Medications',
              icon: Icons.medication_rounded,
              iconColor: AppColors.accent,
              content: dto.currentMedications,
            ),
            const SizedBox(height: 12),

            // Implants Card
            _buildSectionCard(
              title: 'Implants / Devices',
              icon: Icons.biotech_rounded,
              iconColor: Colors.purple,
              content: dto.implants,
            ),
            const SizedBox(height: 12),

            // Doctor & Hospital Card (If present)
            if (dto.primaryDoctor != null || dto.preferredHospital != null) ...[
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.local_hospital_outlined, color: AppColors.accent),
                          SizedBox(width: 10),
                          Text(
                            'Doctor & Hospital Information',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      if (dto.primaryDoctor != null)
                        _buildInfoRow('Primary Doctor', dto.primaryDoctor!),
                      if (dto.preferredHospital != null) ...[
                        const SizedBox(height: 8),
                        _buildInfoRow('Preferred Hospital', dto.preferredHospital!),
                      ],
                      if (dto.hospitalAddress != null && dto.hospitalAddress!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () => _openHospitalDirections(dto.hospitalAddress!),
                          icon: const Icon(Icons.directions_rounded),
                          label: const Text('DIRECTIONS TO HOSPITAL'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Emergency Notes
            if (dto.emergencyNotes.isNotEmpty) ...[
              _buildSectionCard(
                title: 'Emergency Medical Notes',
                icon: Icons.note_alt_rounded,
                iconColor: Colors.teal,
                content: dto.emergencyNotes,
              ),
              const SizedBox(height: 12),
            ],

            // Emergency Contacts
            if (dto.emergencyContacts.isNotEmpty) ...[
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.contacts_rounded, color: AppColors.primary),
                          SizedBox(width: 10),
                          Text(
                            'Emergency Contacts',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      ...dto.emergencyContacts.map((c) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('${c.relationship} • ${c.phoneNumber}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.phone_rounded, color: Colors.green, size: 28),
                              onPressed: () => _makeCall(c.phoneNumber),
                            ),
                          )),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Direct Call Local Emergency Services
            OutlinedButton.icon(
              onPressed: () => _makeCall(AppConfig.defaultEmergencyNumber),
              icon: const Icon(Icons.phone_forwarded_rounded, color: AppColors.primary),
              label: Text(
                'CALL LOCAL EMERGENCY (${AppConfig.defaultEmergencyNumber})',
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontFamily: 'Poppins'),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: AppColors.primary, width: 2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 20),

            // Mandatory Disclaimer
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Text(
                'DISCLAIMER: This emergency information is user-provided and is not a substitute for professional medical assessment or official hospital records.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: Colors.grey, fontFamily: 'Poppins'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required String content,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Text(
              content.isNotEmpty ? content : 'None reported',
              style: const TextStyle(
                fontSize: 14,
                fontFamily: 'Poppins',
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontFamily: 'Poppins')),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
      ],
    );
  }
}
