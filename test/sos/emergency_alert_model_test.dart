import 'package:flutter_test/flutter_test.dart';
import 'package:sozotap/sos/domain/models/emergency_alert_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('EmergencyAlertModel Tests', () {
    final now = DateTime(2026, 9, 5, 12, 0, 0);

    final alertModel = EmergencyAlertModel(
      alertId: 'alert_123',
      ownerUserId: 'user_456',
      status: 'active',
      type: 'manual_sos',
      message: 'Test SOS alert message',
      createdAt: now,
      updatedAt: now,
      resolvedAt: null,
      latitude: 12.9716,
      longitude: 77.5946,
      accuracyMeters: 5.0,
      locationCapturedAt: now,
      locationStatus: 'available',
      liveLocationEnabled: true,
      expiresAt: now.add(const Duration(hours: 24)),
      recipientContactIds: const ['contact_1', 'contact_2'],
      notificationStatus: 'pending',
      failureReason: null,
    );

    test('toFirestore returns correct map structure with Timestamps', () {
      final map = alertModel.toFirestore();

      expect(map['alertId'], 'alert_123');
      expect(map['ownerUserId'], 'user_456');
      expect(map['status'], 'active');
      expect(map['type'], 'manual_sos');
      expect(map['latitude'], 12.9716);
      expect(map['longitude'], 77.5946);
      expect(map['accuracyMeters'], 5.0);
      expect(map['locationStatus'], 'available');
      expect(map['liveLocationEnabled'], true);
      expect(map['recipientContactIds'], ['contact_1', 'contact_2']);
      expect(map['createdAt'], isA<Timestamp>());
      expect(map['updatedAt'], isA<Timestamp>());
    });

    test('fromMap correctly reconstructs EmergencyAlertModel', () {
      final map = {
        'alertId': 'alert_123',
        'ownerUserId': 'user_456',
        'status': 'active',
        'type': 'manual_sos',
        'message': 'Test SOS alert message',
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
        'resolvedAt': null,
        'latitude': 12.9716,
        'longitude': 77.5946,
        'accuracyMeters': 5.0,
        'locationCapturedAt': Timestamp.fromDate(now),
        'locationStatus': 'available',
        'liveLocationEnabled': true,
        'expiresAt': Timestamp.fromDate(now.add(const Duration(hours: 24))),
        'recipientContactIds': ['contact_1', 'contact_2'],
        'notificationStatus': 'pending',
        'failureReason': null,
      };

      final model = EmergencyAlertModel.fromMap(map, id: 'alert_123');

      expect(model.alertId, 'alert_123');
      expect(model.ownerUserId, 'user_456');
      expect(model.status, 'active');
      expect(model.latitude, 12.9716);
      expect(model.recipientContactIds.length, 2);
      expect(model.createdAt, now);
    });

    test('copyWith properly overrides specified fields', () {
      final updatedModel = alertModel.copyWith(
        status: 'resolved',
        resolvedAt: now.add(const Duration(minutes: 10)),
      );

      expect(updatedModel.status, 'resolved');
      expect(updatedModel.resolvedAt, now.add(const Duration(minutes: 10)));
      expect(updatedModel.alertId, 'alert_123');
    });
  });
}
