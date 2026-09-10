import 'package:flutter_test/flutter_test.dart';
import 'package:sozotap/qr/domain/models/emergency_qr_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('EmergencyQrModel Tests', () {
    final now = DateTime(2026, 9, 5, 12, 0, 0);

    test('isActive returns true for active non-expired token', () {
      final model = EmergencyQrModel(
        tokenId: 'qr_123',
        ownerUserId: 'user_456',
        status: 'active',
        createdAt: now,
        expiresAt: now.add(const Duration(days: 90)),
        scanCount: 0,
        allowedFieldsVersion: 1,
        emergencyProfileVersion: 1,
        displayEmergencyId: 'ST-AB7K-92QP',
        notificationOnScan: true,
      );

      expect(model.isActive, isTrue);
    });

    test('isActive returns false for revoked or expired token', () {
      final revokedModel = EmergencyQrModel(
        tokenId: 'qr_123',
        ownerUserId: 'user_456',
        status: 'revoked',
        createdAt: now,
        revokedAt: now,
        scanCount: 0,
        allowedFieldsVersion: 1,
        emergencyProfileVersion: 1,
        displayEmergencyId: 'ST-AB7K-92QP',
        notificationOnScan: true,
      );

      expect(revokedModel.isActive, isFalse);

      final expiredModel = EmergencyQrModel(
        tokenId: 'qr_124',
        ownerUserId: 'user_456',
        status: 'active',
        createdAt: now.subtract(const Duration(days: 100)),
        expiresAt: now.subtract(const Duration(days: 10)),
        scanCount: 5,
        allowedFieldsVersion: 1,
        emergencyProfileVersion: 1,
        displayEmergencyId: 'ST-AB7K-92QP',
        notificationOnScan: true,
      );

      expect(expiredModel.isActive, isFalse);
    });

    test('fromMap deserializes Firestore data properly', () {
      final map = {
        'tokenId': 'qr_123',
        'ownerUserId': 'user_456',
        'status': 'active',
        'createdAt': Timestamp.fromDate(now),
        'expiresAt': Timestamp.fromDate(now.add(const Duration(days: 90))),
        'scanCount': 3,
        'allowedFieldsVersion': 1,
        'emergencyProfileVersion': 2,
        'displayEmergencyId': 'ST-AB7K-92QP',
        'notificationOnScan': true,
      };

      final model = EmergencyQrModel.fromMap(map, id: 'qr_123');

      expect(model.tokenId, 'qr_123');
      expect(model.scanCount, 3);
      expect(model.displayEmergencyId, 'ST-AB7K-92QP');
      expect(model.isActive, isTrue);
    });
  });
}
