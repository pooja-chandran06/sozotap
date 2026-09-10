import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../constants/app_colors.dart';
import '../providers/qr_providers.dart';

class QrDashboardCardWidget extends ConsumerWidget {
  const QrDashboardCardWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeQrAsync = ref.watch(watchActiveQrMetadataProvider);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => context.push('/my-emergency-qr'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.qr_code_2_rounded,
                  color: AppColors.accent,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Emergency Medical QR',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 4),
                    activeQrAsync.when(
                      data: (qr) => Text(
                        qr != null && qr.isActive
                            ? 'Active Key: ${qr.displayEmergencyId}'
                            : 'Tap to generate secure QR key',
                        style: TextStyle(
                          fontSize: 12,
                          color: qr != null && qr.isActive ? Colors.green.shade700 : AppColors.textSecondary,
                          fontWeight: qr != null && qr.isActive ? FontWeight.bold : FontWeight.normal,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      loading: () => const Text('Loading QR status...', style: TextStyle(fontSize: 12)),
                      error: (_, __) => const Text('Tap to view Emergency QR', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
