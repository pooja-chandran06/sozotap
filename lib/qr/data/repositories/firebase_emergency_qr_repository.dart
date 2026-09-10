import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';
import '../../domain/models/emergency_qr_model.dart';
import '../../domain/repositories/emergency_qr_repository.dart';

class FirebaseEmergencyQrRepository implements EmergencyQrRepository {
  final FirebaseFunctions _functions;
  final FirebaseFirestore _firestore;
  final Logger _logger = Logger();

  FirebaseEmergencyQrRepository({
    FirebaseFunctions? functions,
    FirebaseFirestore? firestore,
  })  : _functions = functions ?? FirebaseFunctions.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<Map<String, dynamic>> createEmergencyQr() async {
    try {
      _logger.i('Calling createEmergencyQr Cloud Function...');
      final callable = _functions.httpsCallable('createEmergencyQr');
      final result = await callable.call();
      return Map<String, dynamic>.from(result.data as Map);
    } catch (e, stackTrace) {
      _logger.e('Failed to create emergency QR code', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> revokeEmergencyQr(String tokenId) async {
    try {
      _logger.i('Calling revokeEmergencyQr Cloud Function for tokenId: $tokenId');
      final callable = _functions.httpsCallable('revokeEmergencyQr');
      await callable.call({'tokenId': tokenId});
    } catch (e, stackTrace) {
      _logger.e('Failed to revoke emergency QR token $tokenId', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> regenerateEmergencyQr() async {
    try {
      _logger.i('Calling regenerateEmergencyQr Cloud Function...');
      final callable = _functions.httpsCallable('regenerateEmergencyQr');
      final result = await callable.call();
      return Map<String, dynamic>.from(result.data as Map);
    } catch (e, stackTrace) {
      _logger.e('Failed to regenerate emergency QR code', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<EmergencyQrModel?> getActiveQrMetadata() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    try {
      final snapshot = await _firestore
          .collection('emergency_qr_tokens')
          .where('ownerUserId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'active')
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;
      return EmergencyQrModel.fromFirestore(snapshot.docs.first);
    } catch (e, stackTrace) {
      _logger.e('Error fetching active QR metadata', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  @override
  Stream<EmergencyQrModel?> watchActiveQrMetadata() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value(null);

    return _firestore
        .collection('emergency_qr_tokens')
        .where('ownerUserId', isEqualTo: user.uid)
        .where('status', isEqualTo: 'active')
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return EmergencyQrModel.fromFirestore(snapshot.docs.first);
    });
  }
}
