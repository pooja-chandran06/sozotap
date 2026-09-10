import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';

class PermissionEducationDialog extends StatelessWidget {
  const PermissionEducationDialog({super.key});

  static Future<bool> show(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const PermissionEducationDialog(),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: const [
          Icon(Icons.shield_rounded, color: AppColors.primary, size: 28),
          SizedBox(width: 10),
          Text(
            'Enable Emergency Alerts',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'SOZOTAP requires notification permission so that you receive instant high-priority alerts when a trusted contact broadcasts an emergency SOS.',
            style: TextStyle(
              fontSize: 14,
              fontFamily: 'Poppins',
              height: 1.4,
            ),
          ),
          SizedBox(height: 12),
          Text(
            '• Immediate delivery of emergency broadcast alerts\n• Audio alerts even when device is locked\n• Quick navigation to location updates',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontFamily: 'Poppins',
              height: 1.5,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Not Now', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Continue'),
        ),
      ],
    );
  }
}
