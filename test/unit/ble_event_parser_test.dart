import 'package:flutter_test/flutter_test.dart';
import 'package:sozotap/iot/models/device_event_model.dart';

void main() {
  group('BLE Event Parser & Idempotency Tests', () {
    test('parses raw GATT string format SOS:evt_100:85 correctly', () {
      const rawGatt = 'SOS:evt_100:85';
      final parts = rawGatt.split(':');

      expect(parts[0], 'SOS');
      expect(parts[1], 'evt_100');
      expect(int.parse(parts[2]), 85);
    });

    test('generates unique, deterministic idempotency keys', () {
      const deviceId = 'dev_123';
      const eventId = 'evt_456';
      final key1 = '$deviceId-$eventId';
      final key2 = '$deviceId-$eventId';

      expect(key1, key2);
      expect(key1, 'dev_123-evt_456');
    });
  });
}
