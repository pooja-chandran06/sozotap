import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../constants/app_colors.dart';
import '../providers/qr_providers.dart';

class QrSettingsSheet extends ConsumerWidget {
  const QrSettingsSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const QrSettingsSheet(),
    );
  }

  Future<void> _confirmRegenerate(BuildContext context, WidgetRef ref) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Regenerate Emergency QR?'),
        content: const Text(
          'Regenerating will immediately revoke your current QR code key. Any printed cards or stored images using the old QR code will stop working. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Regenerate Now'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      Navigator.pop(context); // Close sheet
      await ref.read(qrControllerProvider.notifier).regenerateQr();
    }
  }

  Future<void> _confirmRevoke(BuildContext context, WidgetRef ref, String tokenId) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revoke Emergency QR?'),
        content: const Text(
          'Are you sure you want to revoke this QR code? First responders will no longer be able to access your medical key using this QR.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep Active'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade900, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Revoke QR'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      Navigator.pop(context); // Close sheet
      await ref.read(qrControllerProvider.notifier).revokeQr(tokenId);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final qrState = ref.watch(qrControllerProvider);
    final metadata = qrState.activeMetadata;

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
            'Emergency QR Security Settings',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),

          if (metadata != null) ...[
            Card(
              elevation: 0,
              color: Colors.grey.shade100,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildAuditRow(
                      label: 'Emergency Backup ID',
                      value: metadata.displayEmergencyId,
                    ),
                    const Divider(height: 16),
                    _buildAuditRow(
                      label: 'Total Scans Recorded',
                      value: '${metadata.scanCount}',
                    ),
                    const Divider(height: 16),
                    _buildAuditRow(
                      label: 'Last Scanned At',
                      value: metadata.lastScannedAt != null
                          ? DateFormat.yMMMd().add_jm().format(metadata.lastScannedAt!)
                          : 'Never Scanned',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: () => _confirmRegenerate(context, ref),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('REGENERATE NEW QR CODE'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),

            OutlinedButton.icon(
              onPressed: () => _confirmRevoke(context, ref, metadata.tokenId),
              icon: const Icon(Icons.block_rounded, color: Colors.red),
              label: const Text('REVOKE CURRENT QR CODE', style: TextStyle(color: Colors.red)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: Colors.red, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ] else ...[
            const Text(
              'No active QR code token found.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildAuditRow({required String label, required String value}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontFamily: 'Poppins')),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
      ],
    );
  }
}
