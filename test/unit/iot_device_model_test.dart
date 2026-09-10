import 'package:flutter_test/flutter_test.dart';
import 'package:sozotap/iot/models/iot_device_model.dart';

void main() {
  group('IoTDevice Model Unit Tests', () {
    test('serializes and deserializes IoTDevice correctly', () {
      final now = DateTime.now();
      final device = IoTDevice(
        deviceId: 'dev_esp32_001',
        ownerUserId: 'user_abc123',
        displayName: 'SOZOTAP Smart Ring',
        connectionType: ConnectionType.ble,
        status: DeviceStatus.paired,
        batteryLevel: 92,
        pairedAt: now,
        createdAt: now,
        updatedAt: now,
      );

      final json = device.toJson();
      final restored = IoTDevice.fromJson(json);

      expect(restored.deviceId, 'dev_esp32_001');
      expect(restored.ownerUserId, 'user_abc123');
      expect(restored.displayName, 'SOZOTAP Smart Ring');
      expect(restored.connectionType, ConnectionType.ble);
      expect(restored.status, DeviceStatus.paired);
      expect(restored.batteryLevel, 92);
    });
  });
}
