import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../constants/app_colors.dart';

class EmergencyCard extends StatelessWidget {
  const EmergencyCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/emergency-contacts'),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.contact_phone_rounded, color: AppColors.accent, size: 32),
              ),
              const Spacer(),
              const Text(
                'Emergency Contacts',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
              ),
              const SizedBox(height: 4),
              const Text(
                'Family, doctor & SOS notification channels',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
