import 'package:cloud_firestore/cloud_firestore.dart';
import 'dispatch_service.dart';
import '../config/app_config.dart';
import '../../utils/logger.dart';

class FirestorePushDispatchService implements DispatchService {
  final FirebaseFirestore _firestore;

  FirestorePushDispatchService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<String> sendNotification({
    required String to,
    required NotificationChannel channel,
    String? subject,
    required String body,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final docRef = await _firestore.collection(AppConfig.firestorePushCollection).add({
        'toUserId': to, // Assuming `to` is the target user's UID in this context
        'title': subject ?? 'SOS Alert',
        'body': body,
        'data': metadata, // Passed from TemplateService
        'status': 'queued',
        'channel': 'push',
        'createdAt': FieldValue.serverTimestamp(),
      });
      AppLogger.i('Firestore Push document queued successfully for user: $to');
      return docRef.id;
    } catch (e, st) {
      AppLogger.e('Failed to write Firestore Push document', e, st);
      throw Exception('Failed to queue Push Notification via Firestore.');
    }
  }
}
