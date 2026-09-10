import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../constants/app_colors.dart';
import '../../domain/models/emergency_qr_model.dart';
import '../providers/qr_providers.dart';
import '../widgets/qr_settings_sheet.dart';

class MyEmergencyQrScreen extends ConsumerStatefulWidget {
  const MyEmergencyQrScreen({super.key});

  @override
  ConsumerState<MyEmergencyQrScreen> createState() => _MyEmergencyQrScreenState();
}

class _MyEmergencyQrScreenState extends ConsumerState<MyEmergencyQrScreen> {
  final GlobalKey _repaintBoundaryKey = GlobalKey();
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(qrControllerProvider);
      if (state.activeMetadata == null && !state.isLoading) {
        ref.read(qrControllerProvider.notifier).issueOrCreateQr();
      }
    });
  }

  Future<void> _shareQrCode() async {
    setState(() => _isExporting = true);
    try {
      final boundary =
          _repaintBoundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/SOZOTAP_Emergency_QR.png');
      await file.writeAsBytes(byteData.buffer.asUint8List());

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'SOZOTAP Emergency Medical QR Code',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share QR image: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeQrAsync = ref.watch(watchActiveQrMetadataProvider);
    final qrState = ref.watch(qrControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Emergency QR',
          style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'QR Settings',
            onPressed: () => QrSettingsSheet.show(context),
          ),
        ],
      ),
      body: activeQrAsync.when(
        data: (metadata) {
          final currentMetadata = metadata ?? qrState.activeMetadata;

          if (currentMetadata == null || !currentMetadata.isActive) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.qr_code_2_rounded, size: 80, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text(
                      'No Active Emergency QR',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Issue a dynamic, cryptographically secure QR code for emergency responders.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontFamily: 'Poppins'),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: qrState.isLoading
                          ? null
                          : () => ref.read(qrControllerProvider.notifier).issueOrCreateQr(),
                      icon: const Icon(Icons.add_a_photo_rounded),
                      label: const Text('ISSUE EMERGENCY QR CODE'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final String qrPayload =
              qrState.rawPayload ?? 'https://sozotap.com/qr/${currentMetadata.tokenId}';
          final String formattedExpiry = currentMetadata.expiresAt != null
              ? DateFormat.yMMMd().format(currentMetadata.expiresAt!)
              : 'No Expiration';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // RepaintBoundary wrapping card for high-res PNG export
                RepaintBoundary(
                  key: _repaintBoundaryKey,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 16,
                          offset: Offset(0, 6),
                        ),
                      ],
                      border: Border.all(color: Colors.grey.shade200, width: 2),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'SOZOTAP EMERGENCY KEY',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                            color: AppColors.primary,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 16),

                        // High Contrast QR View with Quiet Zone
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.black12, width: 1),
                          ),
                          child: QrImageView(
                            data: qrPayload,
                            version: QrVersions.auto,
                            size: 220.0,
                            errorCorrectionLevel: QrErrorCorrectLevel.Q,
                            backgroundColor: Colors.white,
                            eyeStyle: const QrEyeStyle(
                              eyeShape: QrEyeShape.square,
                              color: Colors.black,
                            ),
                            dataModuleStyle: const QrDataModuleStyle(
                              dataModuleShape: QrDataModuleShape.square,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Short Human-Readable Emergency ID for Printed Backup
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                'BACKUP EMERGENCY ID',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                  letterSpacing: 1,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                currentMetadata.displayEmergencyId,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2,
                                  color: AppColors.textPrimary,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        Text(
                          'Expires: $formattedExpiry',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Critical Security Warning Banner
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.amber.shade700, width: 1.2),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.security_rounded, color: Colors.amber, size: 28),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'SECURITY NOTICE: This QR code contains no medical details in plaintext. It is a cryptographically secure access key. Replace or revoke it if lost or copied.',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.black87,
                            height: 1.4,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isExporting ? null : _shareQrCode,
                        icon: _isExporting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Icon(Icons.share_rounded),
                        label: const Text('SHARE QR'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => QrSettingsSheet.show(context),
                        icon: const Icon(Icons.tune_rounded, color: AppColors.accent),
                        label: const Text('MANAGE QR'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: AppColors.accent, width: 2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading QR code: $err')),
      ),
    );
  }
}
