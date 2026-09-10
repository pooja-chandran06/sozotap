import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:sozotap/core/logging/safe_logger.dart';
import 'package:sozotap/iot/models/iot_device_model.dart';
import 'package:sozotap/iot/models/device_event_model.dart';
import 'package:sozotap/iot/domain/repositories/iot_device_repository.dart';

class BleSosService {
  static const String sozotapServiceUuid = '0000SOZO-0000-1000-8000-00805F9B34FB';
  static const String sosCharacteristicUuid = '0000SOZO-0001-1000-8000-00805F9B34FB';

  final IoTDeviceRepository _deviceRepository;
  final Function(DeviceEvent)? _onSosEventTriggered;
  final Set<String> _processedIdempotencyKeys = {};

  StreamSubscription? _scanSubscription;
  StreamSubscription? _characteristicSubscription;
  BluetoothDevice? _connectedDevice;

  BleSosService({
    required IoTDeviceRepository deviceRepository,
    Function(DeviceEvent)? onSosEventTriggered,
  })  : _deviceRepository = deviceRepository,
        _onSosEventTriggered = onSosEventTriggered;

  /// Scan for nearby BLE devices
  Stream<List<ScanResult>> scanForDevices({Duration timeout = const Duration(seconds: 15)}) {
    SafeLogger.info('Starting BLE device scan for SOZOTAP wearables...');
    FlutterBluePlus.startScan(timeout: timeout);
    return FlutterBluePlus.scanResults;
  }

  /// Connect to selected BLE device & subscribe to GATT SOS characteristic
  Future<bool> connectAndPair(BluetoothDevice device, String ownerUserId) async {
    try {
      SafeLogger.info('Connecting to BLE device ${device.remoteId.str}...');
      await device.connect(autoConnect: false);
      _connectedDevice = device;

      final services = await device.discoverServices();
      for (final service in services) {
        for (final characteristic in service.characteristics) {
          if (characteristic.properties.notify || characteristic.properties.indicate) {
            await characteristic.setNotifyValue(true);
            _characteristicSubscription = characteristic.lastValueStream.listen((data) {
              _handleIncomingGattData(data, device.remoteId.str, ownerUserId);
            });
            SafeLogger.info('Subscribed to BLE GATT SOS characteristic successfully');
          }
        }
      }

      final newDevice = IoTDevice(
        deviceId: device.remoteId.str,
        ownerUserId: ownerUserId,
        displayName: device.platformName.isNotEmpty ? device.platformName : 'SOZOTAP Wearable',
        connectionType: ConnectionType.ble,
        status: DeviceStatus.paired,
        pairedAt: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _deviceRepository.pairDevice(newDevice);
      return true;
    } catch (e) {
      SafeLogger.error('Failed to connect/pair BLE device: $e');
      await disconnect();
      return false;
    }
  }

  void _handleIncomingGattData(List<int> data, String deviceId, String ownerUserId) {
    if (data.isEmpty) return;

    final rawString = String.fromCharCodes(data).trim();
    SafeLogger.info('Incoming BLE GATT event received from $deviceId');

    // Expected format: SOS:<eventId>:<batteryLevel>
    final parts = rawString.split(':');
    final eventTypeStr = parts.isNotEmpty ? parts[0] : 'SOS';
    final eventId = parts.length > 1 ? parts[1] : 'evt_${DateTime.now().millisecondsSinceEpoch}';
    final battery = parts.length > 2 ? int.tryParse(parts[2]) : 100;

    final idempotencyKey = '$deviceId-$eventId';
    if (_processedIdempotencyKeys.contains(idempotencyKey)) {
      SafeLogger.warn('Duplicate BLE SOS payload ignored with key $idempotencyKey');
      return;
    }
    _processedIdempotencyKeys.add(idempotencyKey);

    final event = DeviceEvent(
      eventId: eventId,
      deviceId: deviceId,
      ownerUserId: ownerUserId,
      type: eventTypeStr == 'FALL' ? DeviceEventType.fall_candidate : DeviceEventType.sos_pressed,
      createdAt: DateTime.now(),
      status: DeviceEventStatus.received,
      batteryLevel: battery,
      payload: {'source': 'BLE_GATT', 'raw': rawString},
      idempotencyKey: idempotencyKey,
    );

    _deviceRepository.recordDeviceEvent(event);
    if (_onSosEventTriggered != null) {
      _onSosEventTriggered!(event);
    }
  }

  Future<void> disconnect() async {
    await _characteristicSubscription?.cancel();
    await _scanSubscription?.cancel();
    if (_connectedDevice != null) {
      await _connectedDevice!.disconnect();
      _connectedDevice = null;
    }
    SafeLogger.info('BLE SOS Service disconnected cleanly');
  }
}
