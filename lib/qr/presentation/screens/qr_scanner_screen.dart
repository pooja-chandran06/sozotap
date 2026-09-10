import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../constants/app_colors.dart';
import '../domain/models/public_emergency_dto.dart';
import 'public_emergency_view_screen.dart';

class QrScannerScreen extends ConsumerStatefulWidget {
  const QrScannerScreen({super.key});

  @override
  ConsumerState<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends ConsumerState<QrScannerScreen> {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  bool _isProcessingScan = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _processQrToken(String rawToken, String sourceType) async {
    if (_isProcessingScan) return;
    setState(() => _isProcessingScan = true);

    try {
      await _scannerController.stop();

      final callable = FirebaseFunctions.instance.httpsCallable('resolveEmergencyQr');
      final result = await callable.call({
        'token': rawToken,
        'sourceType': sourceType,
      });

      if (result.data == null) {
        throw Exception('invalid_token');
      }

      final dto = PublicEmergencyDto.fromMap(Map<String, dynamic>.from(result.data as Map));

      if (mounted) {
        // Navigate safely to PublicEmergencyViewScreen without exposing raw token in URL
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => PublicEmergencyViewScreen(dto: dto),
          ),
        );
      }
    } catch (e) {
      final String errorMessage = _mapScanError(e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red.shade900,
            duration: const Duration(seconds: 4),
          ),
        );
        _scannerController.start();
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessingScan = false);
      }
    }
  }

  String _mapScanError(dynamic error) {
    final str = error.toString();
    if (str.contains('expired_token')) {
      return 'This Emergency QR code has expired.';
    } else if (str.contains('revoked_token')) {
      return 'This Emergency QR code has been revoked by the owner.';
    } else if (str.contains('invalid_token')) {
      return 'Invalid Emergency QR code payload.';
    } else if (str.contains('rate_limited')) {
      return 'Too many scan requests. Please try again shortly.';
    }
    return 'Failed to resolve emergency QR code. Check internet connection.';
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      final capture = await _scannerController.analyzeImage(image.path);
      if (capture != null && capture.barcodes.isNotEmpty) {
        final barcode = capture.barcodes.first;
        if (barcode.rawValue != null) {
          await _processQrToken(barcode.rawValue!, 'gallery');
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No QR code detected in selected image.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to analyze image: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Scan Emergency QR',
          style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on_rounded),
            onPressed: () => _scannerController.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.photo_library_rounded),
            tooltip: 'Scan Image from Gallery',
            onPressed: _pickImageFromGallery,
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _scannerController,
            onDetect: (capture) {
              final barcodes = capture.barcodes;
              if (barcodes.isNotEmpty && !_isProcessingScan) {
                final rawValue = barcodes.first.rawValue;
                if (rawValue != null && rawValue.isNotEmpty) {
                  _processQrToken(rawValue, 'camera');
                }
              }
            },
            errorBuilder: (context, error, child) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.videocam_off_rounded, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text(
                        'Camera Unavailable',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please grant camera permission in system settings to scan QR tags.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade700, fontFamily: 'Poppins'),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () => context.push('/manual-emergency-lookup'),
                        icon: const Icon(Icons.keyboard_rounded),
                        label: const Text('ENTER EMERGENCY ID MANUALLY'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Scanner Overlay Frame
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primary, width: 3),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),

          if (_isProcessingScan)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Verifying Emergency Key...',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),

          // Bottom Fallback Button
          Positioned(
            bottom: 32,
            left: 24,
            right: 24,
            child: ElevatedButton.icon(
              onPressed: () => context.push('/manual-emergency-lookup'),
              icon: const Icon(Icons.pin_rounded),
              label: const Text('MANUAL EMERGENCY LOOKUP'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black87,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
