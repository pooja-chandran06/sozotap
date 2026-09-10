import 'package:flutter_test/flutter_test.dart';
import 'package:sozotap/notifications/domain/models/device_token_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('DeviceTokenModel Tests', () {
    final now = DateTime(2026, 9, 5, 12, 0, 0);

    test('toFirestore serialization returns correct structure', () {
      final tokenModel = DeviceTokenModel(
        tokenId: 'token_123',
        token: 'fcm_raw_token_xyz',
        platform: 'android',
        appVersion: '1.0.0',
        deviceIdHash: 'hash_abc',
        createdAt: now,
        updatedAt: now,
        lastSeenAt: now,
        enabled: true,
        notificationPermissionStatus: 'granted',
      );

      final map = tokenModel.toFirestore();

      expect(map['tokenId'], 'token_123');
      expect(map['token'], 'fcm_raw_token_xyz');
      expect(map['platform'], 'android');
      expect(map['enabled'], true);
      expect(map['createdAt'], isA<Timestamp>());
    });

    test('fromMap deserialization parses map properly', () {
      final map = {
        'tokenId': 'token_123',
        'token': 'fcm_raw_token_xyz',
        'platform': 'android',
        'appVersion': '1.0.0',
        'deviceIdHash': 'hash_abc',
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
        'lastSeenAt': Timestamp.fromDate(now),
        'enabled': true,
        'notificationPermissionStatus': 'granted',
      };

      final model = DeviceTokenModel.fromMap(map, id: 'token_123');

      expect(model.tokenId, 'token_123');
      expect(model.enabled, isTrue);
      expect(model.platform, 'android');
    });
  });
}
