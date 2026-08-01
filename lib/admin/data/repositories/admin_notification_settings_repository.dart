import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/admin_notification_settings.dart';
import '../../../utils/logger.dart';

class AdminNotificationSettingsRepository {
  final FirebaseFirestore _firestore;

  AdminNotificationSettingsRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<AdminNotificationSettings> getSettings(String uid) async {
    if (uid.isEmpty) {
      return AdminNotificationSettings(
        uid: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }

    try {
      final doc = await _firestore.collection('admin_notification_settings').doc(uid).get();
      if (doc.exists) {
        return AdminNotificationSettings.fromFirestore(doc);
      }
    } catch (e, st) {
      AppLogger.e('Failed to fetch admin notification settings for $uid', e, st);
    }

    return AdminNotificationSettings(
      uid: uid,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  Future<void> saveSettings(AdminNotificationSettings settings) async {
    try {
      final docRef = _firestore.collection('admin_notification_settings').doc(settings.uid);
      final data = settings.toFirestore();
      
      final doc = await docRef.get();
      if (!doc.exists) {
        data['createdAt'] = FieldValue.serverTimestamp();
      }

      await docRef.set(data, SetOptions(merge: true));
      AppLogger.i('Admin notification settings saved for ${settings.uid}');
    } catch (e, st) {
      AppLogger.e('Failed to save admin notification settings for ${settings.uid}', e, st);
      rethrow;
    }
  }
}
