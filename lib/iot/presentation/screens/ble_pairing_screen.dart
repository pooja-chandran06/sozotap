import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sozotap/iot/providers/iot_providers.dart';
import 'package:sozotap/iot/services/ble_sos_service.dart';

class BlePairingScreen extends ConsumerStatefulWidget {
  const BlePairingScreen({super.key});

  @override
  ConsumerState<BlePairingScreen> createState() => _BlePairingScreenState();
}

class _BlePairingScreenState extends ConsumerState<BlePairingScreen> {
  BleSosService? _bleService;
  bool _isScanning = false;
  bool _isPairing = false;
  List<ScanResult> _scanResults = [];
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    final repo = ref.read(ioTDeviceRepositoryProvider);
    _bleService = BleSosService(deviceRepository: repo);
    _startScan();
  }

  void _startScan() {
    setState(() {
      _isScanning = true;
      _statusMessage = 'Scanning for nearby SOZOTAP BLE Wearables & Buttons...';
    });

    _bleService?.scanForDevices().listen((results) {
      if (mounted) {
        setState(() {
          _scanResults = results;
        });
      }
    }, onDone: () {
      if (mounted) {
        setState(() {
          _isScanning = false;
          _statusMessage = _scanResults.isEmpty ? 'No BLE devices found. Ensure device is powered on.' : null;
        });
      }
    });
  }

  Future<void> _pairDevice(BluetoothDevice device) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() {
      _isPairing = true;
      _statusMessage = 'Pairing with ${device.platformName.isNotEmpty ? device.platformName : device.remoteId.str}...';
    });

    final success = await _bleService?.connectAndPair(device, uid) ?? false;

    if (mounted) {
      setState(() => _isPairing = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(backgroundColor: Colors.green, content: Text('Device paired successfully!')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(backgroundColor: Colors.red, content: Text('Failed to pair device. Try again.')),
        );
      }
    }
  }

  @override
  void dispose() {
    _bleService?.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1C1E),
        title: const Text('Pair BLE Wearable', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF0A84FF)),
            onPressed: _isScanning || _isPairing ? null : _startScan,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isScanning || _isPairing)
            const LinearProgressIndicator(color: Color(0xFF0A84FF), backgroundColor: Color(0xFF1C1C1E)),

          if (_statusMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: const Color(0xFF1C1C1E),
              child: Text(
                _statusMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ),

          Expanded(
            child: _scanResults.isEmpty
                ? const Center(
                    child: Text('Searching for Bluetooth Low Energy devices...', style: TextStyle(color: Colors.grey)),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _scanResults.length,
                    itemBuilder: (context, index) {
                      final res = _scanResults[index];
                      final name = res.device.platformName.isNotEmpty ? res.device.platformName : 'Unknown BLE Device';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(color: const Color(0xFF1C1C1E), borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: const Icon(Icons.bluetooth_searching_rounded, color: Color(0xFF0A84FF)),
                          title: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          subtitle: Text('ID: ${res.device.remoteId.str} • RSSI: ${res.rssi} dBm', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          trailing: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0A84FF)),
                            onPressed: _isPairing ? null : () => _pairDevice(res.device),
                            child: const Text('Pair', style: TextStyle(color: Colors.white)),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
