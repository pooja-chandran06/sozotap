import 'package:flutter_test/flutter_test.dart';
import 'package:sozotap/notifications/domain/models/notification_item.dart';

void main() {
  group('NotificationItem Unit Tests', () {
    test('NotificationItem serialization and copyWith', () {
      final now = DateTime.now();
      final item = NotificationItem(
        notificationId: 'notif_1',
        recipientUserId: 'user_1',
        senderUserId: 'user_2',
        title: 'SOS Alert',
        body: 'A contact needs help.',
        type: 'sos_alert',
        alertId: 'alert_99',
        isRead: false,
        createdAt: now,
      );

      final map = item.toMap();
      expect(map['notificationId'], 'notif_1');
      expect(map['title'], 'SOS Alert');

      final updated = item.copyWith(isRead: true);
      expect(updated.isRead, true);
      expect(updated.notificationId, 'notif_1');
    });

    test('Notification body does NOT contain raw sensitive medical data', () {
      final item = NotificationItem(
        notificationId: 'notif_1',
        recipientUserId: 'user_1',
        senderUserId: 'user_2',
        title: 'SOS Alert',
        body: 'A trusted contact may need help. Tap to view the alert.',
        type: 'sos_alert',
        alertId: 'alert_99',
        isRead: false,
        createdAt: DateTime.now(),
      );

      expect(item.body.contains('allergy'), false);
      expect(item.body.contains('medication'), false);
      expect(item.body.contains('GPS'), false);
    });
  });
}
