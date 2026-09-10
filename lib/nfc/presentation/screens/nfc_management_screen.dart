import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sozotap/nfc/domain/repositories/nfc_tag_repository.dart';
import 'package:sozotap/nfc/data/repositories/nfc_tag_repository_impl.dart';
import 'package:sozotap/qr/presentation/providers/qr_providers.dart';

final nfcRepositoryProvider = Provider<NfcTagRepository>((ref) {
  return NfcTagRepositoryImpl();
});

class NfcManagementScreen extends ConsumerStatefulWidget {
  const NfcManagementScreen({super.key});

  @override
  ConsumerState<NfcManagementScreen> createState() => _NfcManagementScreenState();
}

class _NfcManagementScreenState extends ConsumerState<NfcManagementScreen> {
  bool _isChecking = true;
  bool _isNfcAvailable = false;
  bool _isProcessing = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState() ;
    _checkNfcStatus();
  }

  Future<void> _checkNfcStatus() async {
    final repo = ref.read(nfcRepositoryProvider);
    final avail = await repo.isNfcAvailable();
    if (mounted) {
      setState(() {
        _isNfcAvailable = avail;
        _isChecking = false;
      });
    }
  }

  Future<void> _writeNfcTag() async {
    final qrState = ref.read(emergencyQrTokenStreamProvider).value;
    if (qrState == null || qrState.token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No active emergency QR token found to write.')),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
      _statusMessage = 'Hold your device near a blank NDEF NFC SmartTag to write...';
    });

    try {
      final repo = ref.read(nfcRepositoryProvider);
      await repo.writeEmergencyTokenTag(qrState.token);
      if (mounted) {
        setState(() {
          _statusMessage = 'NFC SmartTag written successfully!';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(backgroundColor: Colors.green, content: Text('NFC SmartTag updated successfully.')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Error: $e';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.red, content: Text('Failed to write NFC tag: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _readNfcTag() async {
    setState(() {
      _isProcessing = true;
      _statusMessage = 'Hold your device near a SOZOTAP NFC tag to read...';
    });

    try {
      final repo = ref.read(nfcRepositoryProvider);
      final token = await repo.readEmergencyTokenTag();
      if (mounted) {
        if (token != null && token.isNotEmpty) {
          setState(() {
            _statusMessage = 'Valid SOZOTAP NFC Tag Detected!\nToken Prefix: ${token.substring(0, token.length > 8 ? 8 : token.length)}...';
          });
        } else {
          setState(() {
            _statusMessage = 'No valid SOZOTAP emergency token found on this NFC tag.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Error reading tag: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1C1E),
        title: const Text('NFC SmartTag Manager', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: _isChecking
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0A84FF)))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Hardware Status Banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _isNfcAvailable
                        ? const Color(0xFF30D158).withOpacity(0.15)
                        : const Color(0xFFFF9500).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isNfcAvailable ? const Color(0xFF30D158) : const Color(0xFFFF9500),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isNfcAvailable ? Icons.nfc_rounded : Icons.nfc_off_rounded,
                        color: _isNfcAvailable ? const Color(0xFF30D158) : const Color(0xFFFF9500),
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isNfcAvailable ? 'NFC Hardware Available' : 'NFC Hardware Unavailable',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _isNfcAvailable
                                  ? 'Touch an NDEF-compatible NFC tag to program your emergency token.'
                                  : 'NFC is not supported or disabled. Use the QR medical ID if NFC is unavailable.',
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                const Text('NFC SMARTTAG ACTIONS', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),

                // Write NFC Tag Button
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0A84FF),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: (_isNfcAvailable && !_isProcessing) ? _writeNfcTag : null,
                  icon: const Icon(Icons.edit_note_rounded, color: Colors.white),
                  label: const Text('Program SOZOTAP NFC Tag', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),

                const SizedBox(height: 12),

                // Read NFC Tag Button
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF0A84FF)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: (_isNfcAvailable && !_isProcessing) ? _readNfcTag : null,
                  icon: const Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF0A84FF)),
                  label: const Text('Scan & Validate NFC Tag', style: TextStyle(color: Color(0xFF0A84FF), fontWeight: FontWeight.bold, fontSize: 16)),
                ),

                if (_statusMessage != null) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: const Color(0xFF1C1C1E), borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      children: [
                        if (_isProcessing) const Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: CircularProgressIndicator(color: Color(0xFF0A84FF)),
                        ),
                        Text(
                          _statusMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 32),
                // Fallback Disclaimer Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1C1E),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.privacy_tip_outlined, color: Colors.grey, size: 20),
                          SizedBox(width: 8),
                          Text('NFC Security & Privacy Standard', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        'SOZOTAP NFC tags contain ONLY an opaque security token. Zero medical records, names, or contact details are stored directly on the physical chip. Paramedic scanners resolve data securely via encrypted Cloud Functions.',
                        style: TextStyle(color: Colors.grey, fontSize: 12, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
