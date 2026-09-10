import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sozotap/iot/providers/iot_providers.dart';
import 'package:sozotap/iot/models/iot_device_model.dart';

class DeviceManagementScreen extends ConsumerWidget {
  const DeviceManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devicesAsync = ref.watch(userDevicesStreamProvider);
    final repo = ref.watch(ioTDeviceRepositoryProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1C1E),
        title: const Text('Paired Emergency Devices', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.nfc_rounded, color: Color(0xFF0A84FF)),
            tooltip: 'NFC SmartTag Manager',
            onPressed: () => context.push('/devices/nfc'),
          ),
        ],
      ),
      body: devicesAsync.when(
        data: (devices) {
          if (devices.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: const Color(0xFF1C1C1E), shape: BoxShape.circle),
                      child: const Icon(Icons.devices_other_rounded, size: 48, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    const Text('No Devices Paired Yet', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text(
                      'Pair a BLE wearable or ESP32 Wi-Fi/GSM panic button to trigger emergency SOS alerts independently.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0A84FF),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => context.push('/devices/pair'),
                      icon: const Icon(Icons.bluetooth_searching_rounded, color: Colors.white),
                      label: const Text('Pair New Device', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('PAIRED HARDWARE', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                  TextButton.icon(
                    onPressed: () => context.push('/devices/pair'),
                    icon: const Icon(Icons.add, color: Color(0xFF0A84FF), size: 18),
                    label: const Text('Add Device', style: TextStyle(color: Color(0xFF0A84FF), fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...devices.map((device) => _buildDeviceTile(context, ref, device)),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF0A84FF))),
        error: (err, _) => Center(child: Text('Error loading devices: $err', style: const TextStyle(color: Colors.red))),
      ),
    );
  }

  Widget _buildDeviceTile(BuildContext context, WidgetRef ref, IoTDevice device) {
    final repo = ref.watch(ioTDeviceRepositoryProvider);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: const Color(0xFF1C1C1E), borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF0A84FF).withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(
            device.connectionType == ConnectionType.ble
                ? Icons.bluetooth_connected_rounded
                : Icons.wifi_tethering_rounded,
            color: const Color(0xFF0A84FF),
            size: 20,
          ),
        ),
        title: Text(device.displayName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text(
          'Type: ${device.connectionType.name.toUpperCase()} • Paired ${device.pairedAt.toString().substring(0, 10)}\nBattery: ${device.batteryLevel ?? "N/A"}%',
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Color(0xFFFF3B30)),
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: const Color(0xFF1C1C1E),
                title: const Text('Revoke Hardware Device?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                content: Text('Revoking "${device.displayName}" will disconnect it from sending emergency alerts to your account.', style: const TextStyle(color: Colors.grey)),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF3B30)),
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Revoke', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );

            if (confirm == true) {
              await repo.revokeDevice(device.deviceId);
            }
          },
        ),
      ),
    );
  }
}
