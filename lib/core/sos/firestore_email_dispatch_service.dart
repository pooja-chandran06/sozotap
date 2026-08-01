import 'package:cloud_firestore/cloud_firestore.dart';
import 'dispatch_service.dart';
import '../config/app_config.dart';
import '../../utils/logger.dart';

class FirestoreEmailDispatchService implements DispatchService {
  final FirebaseFirestore _firestore;

  FirestoreEmailDispatchService({FirebaseFirestore? firestore})
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
      final docRef = await _firestore.collection(AppConfig.firestoreEmailCollection).add({
        'to': to,
        'message': {
          'subject': subject ?? 'EMERGENCY SOS',
          'html': body,
        },
        'status': 'queued',
        'channel': 'email',
        'createdAt': FieldValue.serverTimestamp(),
        if (metadata != null) ...metadata,
      });
      AppLogger.i('Firestore Email document queued successfully for $to');
      return docRef.id;
    } catch (e, st) {
      AppLogger.e('Failed to write Firestore Email document', e, st);
      throw Exception('Failed to queue Email via Firestore.');
    }
  }
}
