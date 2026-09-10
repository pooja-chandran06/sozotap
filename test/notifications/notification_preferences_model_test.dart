import 'package:flutter_test/flutter_test.dart';
import 'package:sozotap/notifications/domain/models/notification_preferences_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('NotificationPreferencesModel Tests', () {
    test('defaults factory initializes all preferences to true', () {
      final prefs = NotificationPreferencesModel.defaults('user_123');
      expect(prefs.userId, 'user_123');
      expect(prefs.sosAlertsEnabled, isTrue);
      expect(prefs.medicationRemindersEnabled, isTrue);
      expect(prefs.appointmentRemindersEnabled, isTrue);
      expect(prefs.qrScanAlertsEnabled, isTrue);
    });

    test('toFirestore and fromMap serialization roundtrip', () {
      final now = DateTime(2026, 9, 5, 12, 0, 0);
      final prefs = NotificationPreferencesModel(
        userId: 'user_456',
        sosAlertsEnabled: false,
        medicationRemindersEnabled: true,
        appointmentRemindersEnabled: false,
        qrScanAlertsEnabled: true,
        updatedAt: now,
      );

      final map = prefs.toFirestore();
      expect(map['sosAlertsEnabled'], isFalse);
      expect(map['medicationRemindersEnabled'], isTrue);
      expect(map['updatedAt'], isA<Timestamp>());

      final deserialized = NotificationPreferencesModel.fromMap(map, userId: 'user_456');
      expect(deserialized.sosAlertsEnabled, isFalse);
      expect(deserialized.appointmentRemindersEnabled, isFalse);
    });
  });
}
