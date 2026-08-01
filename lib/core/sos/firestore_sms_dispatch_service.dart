import 'package:cloud_firestore/cloud_firestore.dart';
import 'dispatch_service.dart';
import '../config/app_config.dart';
import '../../utils/logger.dart';

class FirestoreSmsDispatchService implements DispatchService {
  final FirebaseFirestore _firestore;

  FirestoreSmsDispatchService({FirebaseFirestore? firestore})
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
      final docRef = await _firestore.collection(AppConfig.firestoreSmsCollection).add({
        'to': to,
        'message': body,
        'status': 'queued',
        'channel': 'sms',
        'createdAt': FieldValue.serverTimestamp(),
        if (metadata != null) ...metadata, // Spread metadata for userId, etc.
      });
      AppLogger.i('Firestore SMS document queued successfully for $to');
      return docRef.id;
    } catch (e, st) {
      AppLogger.e('Failed to write Firestore SMS document', e, st);
      throw Exception('Failed to queue SMS via Firestore.');
    }
  }
}
