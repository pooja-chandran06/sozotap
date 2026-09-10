import 'package:flutter_test/flutter_test.dart';
import 'package:sozotap/models/device_token.dart';

void main() {
  group('DeviceToken Unit Tests', () {
    test('toMap and fromMap serialize properly', () {
      final now = DateTime.now();
      final token = DeviceToken(
        tokenId: 'token123',
        ownerUserId: 'user456',
        token: 'fcm_raw_token_xyz',
        platform: 'android',
        appVersion: '1.0.0',
        notificationPermissionStatus: 'granted',
        enabled: true,
        createdAt: now,
        updatedAt: now,
        lastSeenAt: now,
      );

      final map = token.toMap();
      expect(map['tokenId'], 'token123');
      expect(map['platform'], 'android');
      expect(map['enabled'], true);

      final deserialized = DeviceToken.fromMap({
        'ownerUserId': 'user456',
        'token': 'fcm_raw_token_xyz',
        'platform': 'android',
        'appVersion': '1.0.0',
        'notificationPermissionStatus': 'granted',
        'enabled': true,
      }, 'token123');

      expect(deserialized.tokenId, 'token123');
      expect(deserialized.ownerUserId, 'user456');
      expect(deserialized.enabled, true);
    });
  });
}
