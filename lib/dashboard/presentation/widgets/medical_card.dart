import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../constants/app_colors.dart';

class MedicalCard extends StatelessWidget {
  const MedicalCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/medical-profile'),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.medical_information_rounded, color: AppColors.primary, size: 32),
              ),
              const Spacer(),
              const Text(
                'Medical Profile',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
              ),
              const SizedBox(height: 4),
              const Text(
                'Blood group, allergies, medications & notes',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
