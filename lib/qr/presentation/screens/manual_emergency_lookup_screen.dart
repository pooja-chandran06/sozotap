import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../constants/app_colors.dart';
import '../domain/models/public_emergency_dto.dart';
import 'public_emergency_view_screen.dart';

class ManualEmergencyLookupScreen extends ConsumerStatefulWidget {
  const ManualEmergencyLookupScreen({super.key});

  @override
  ConsumerState<ManualEmergencyLookupScreen> createState() => _ManualEmergencyLookupScreenState();
}

class _ManualEmergencyLookupScreenState extends ConsumerState<ManualEmergencyLookupScreen> {
  final TextEditingController _tokenController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _performLookup() async {
    final input = _tokenController.text.trim();
    if (input.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an Emergency Token or ID.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final callable = FirebaseFunctions.instance.httpsCallable('resolveEmergencyQr');
      final result = await callable.call({
        'token': input,
        'sourceType': 'manual',
      });

      if (result.data == null) {
        throw Exception('invalid_token');
      }

      final dto = PublicEmergencyDto.fromMap(Map<String, dynamic>.from(result.data as Map));

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => PublicEmergencyViewScreen(dto: dto),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lookup failed: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red.shade900,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Manual Emergency Lookup',
          style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Enter Emergency Key or ID',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'If the camera scanner cannot read the QR code, enter the raw QR token string or printed Emergency ID below.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontFamily: 'Poppins'),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _tokenController,
              decoration: InputDecoration(
                labelText: 'Emergency Token / Key',
                hintText: 'e.g. https://sozotap.com/qr/... or ST-AB7K-92QP',
                prefixIcon: const Icon(Icons.key_rounded, color: AppColors.primary),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _performLookup,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.search_rounded),
              label: Text(
                _isLoading ? 'VERIFYING...' : 'RESOLVE EMERGENCY KEY',
                style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
