import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/models/notification_item.dart';
import '../../../models/notification_preference.dart';
import '../../../models/device_token.dart';

class NotificationRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  NotificationRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  String? get _currentUserId => _auth.currentUser?.uid;

  Stream<List<NotificationItem>> getNotificationsStream() {
    final uid = _currentUserId;
    if (uid == null) return Stream.value([]);

    return _firestore
        .collection('notifications')
        .where('recipientUserId', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
      final items = snapshot.docs
          .map((doc) => NotificationItem.fromMap(doc.data(), doc.id))
          .toList();
      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return items;
    });
  }

  Future<void> markAsRead(String notificationId) async {
    final uid = _currentUserId;
    if (uid == null) return;

    await _firestore
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  Future<void> markAllAsRead() async {
    final uid = _currentUserId;
    if (uid == null) return;

    final snapshot = await _firestore
        .collection('notifications')
        .where('recipientUserId', isEqualTo: uid)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  Stream<NotificationPreference> getNotificationPreferencesStream() {
    final uid = _currentUserId;
    if (uid == null) return Stream.value(NotificationPreference());

    return _firestore
        .collection('users')
        .doc(uid)
        .collection('notification_preferences')
        .doc('settings')
        .snapshots()
        .map((snapshot) => NotificationPreference.fromMap(snapshot.data()));
  }

  Future<void> updateNotificationPreferences(NotificationPreference preferences) async {
    final uid = _currentUserId;
    if (uid == null) return;

    await _firestore
        .collection('users')
        .doc(uid)
        .collection('notification_preferences')
        .doc('settings')
        .set(preferences.toMap(), SetOptions(merge: true));
  }

  Stream<List<DeviceToken>> getDeviceTokensStream() {
    final uid = _currentUserId;
    if (uid == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(uid)
        .collection('device_tokens')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DeviceToken.fromMap(doc.data(), doc.id))
            .toList());
  }
}
