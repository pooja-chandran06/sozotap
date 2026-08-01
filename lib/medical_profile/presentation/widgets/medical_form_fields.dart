import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';

class MedicalFormSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const MedicalFormSection({
    super.key,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
              color: AppColors.primary,
            ),
          ),
        ),
        ...children,
        const SizedBox(height: 16),
      ],
    );
  }
}
