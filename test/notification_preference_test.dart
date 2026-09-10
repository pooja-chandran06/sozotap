import 'package:flutter_test/flutter_test.dart';
import 'package:sozotap/models/notification_preference.dart';

void main() {
  group('NotificationPreference Unit Tests', () {
    test('Default values are all enabled for safety', () {
      final pref = NotificationPreference();
      expect(pref.sosPushEnabled, true);
      expect(pref.sosSmsEnabled, true);
      expect(pref.medicationReminderEnabled, true);
    });

    test('copyWith modifies selected toggle fields', () {
      final pref = NotificationPreference();
      final updated = pref.copyWith(sosPushEnabled: false, sosSmsEnabled: true);
      expect(updated.sosPushEnabled, false);
      expect(updated.sosSmsEnabled, true);
    });
  });
}
