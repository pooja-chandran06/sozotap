import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:sozotap/core/logging/safe_logger.dart';
import '../../domain/models/emergency_qr_model.dart';
import '../../domain/models/public_emergency_dto.dart';
import '../../domain/repositories/emergency_qr_repository.dart';

class FirebaseEmergencyQrRepository implements EmergencyQrRepository {
  final FirebaseFirestore _firestore;
  final Logger _logger = Logger();

  FirebaseEmergencyQrRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  String _generateOpaqueToken() {
    final random = Random.secure();
    final values = List<int>.generate(32, (_) => random.nextInt(256));
    return values.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  String _hashToken(String token) {
    final bytes = utf8.encode(token);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  String _generateDisplayEmergencyId() {
    final random = Random.secure();
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final p1 = List.generate(4, (_) => chars[random.nextInt(chars.length)]).join();
    final p2 = List.generate(4, (_) => chars[random.nextInt(chars.length)]).join();
    return 'ST-$p1-$p2';
  }

  @override
  Future<Map<String, dynamic>> createEmergencyQr() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      SafeLogger.info('[TRACE_QR] ERROR: User not authenticated');
      throw Exception('User not authenticated.');
    }

    final userId = user.uid;
    SafeLogger.info('[TRACE_QR] REPOSITORY_CREATE_START uid=$userId');

    try {
      SafeLogger.info('[TRACE_QR] QUERY_EXISTING_TOKENS_START uid=$userId');
      final existingTokensSnapshot = await _firestore
          .collection('emergency_qr_tokens')
          .where('ownerUserId', isEqualTo: userId)
          .where('status', isEqualTo: 'active')
          .get()
          .timeout(const Duration(seconds: 10));
      SafeLogger.info('[TRACE_QR] QUERY_EXISTING_TOKENS_END existingCount=${existingTokensSnapshot.docs.length}');

      final batch = _firestore.batch();
      for (final doc in existingTokensSnapshot.docs) {
        batch.update(doc.reference, {
          'status': 'revoked',
          'revokedAt': FieldValue.serverTimestamp(),
        });
      }

      SafeLogger.info('[TRACE_QR] TOKEN_GENERATION_START');
      final rawToken = _generateOpaqueToken();
      SafeLogger.info('[TRACE_QR] TOKEN_GENERATION_END');

      SafeLogger.info('[TRACE_QR] HASH_START');
      final tokenHash = _hashToken(rawToken);
      SafeLogger.info('[TRACE_QR] HASH_END');

      final displayEmergencyId = _generateDisplayEmergencyId();
      final tokenRef = _firestore.collection('emergency_qr_tokens').doc();
      final now = DateTime.now();
      final expiresAt = now.add(const Duration(days: 90));

      final tokenData = {
        'tokenId': tokenRef.id,
        'ownerUserId': userId,
        'tokenHash': tokenHash,
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(expiresAt),
        'revokedAt': null,
        'lastScannedAt': null,
        'scanCount': 0,
        'allowedFieldsVersion': 1,
        'emergencyProfileVersion': 1,
        'displayEmergencyId': displayEmergencyId,
        'notificationOnScan': true,
        'lastScanMetadata': null,
      };

      batch.set(tokenRef, tokenData);

      SafeLogger.info('[TRACE_QR] FIRESTORE_CREATE_START tokenId=${tokenRef.id}');
      await batch.commit().timeout(const Duration(seconds: 15));
      SafeLogger.info('[TRACE_QR] FIRESTORE_CREATE_END tokenId=${tokenRef.id}');
      SafeLogger.info('[TRACE_QR] TOKEN_DOCUMENT_CREATED tokenId=${tokenRef.id}');

      SafeLogger.info('[TRACE_QR] PAYLOAD_CREATE_START');
      final payloadUrl = 'https://sozotap.web.app/emergency/$rawToken';
      SafeLogger.info('[TRACE_QR] PAYLOAD_CREATE_END payloadUrl=$payloadUrl');

      return {
        'tokenId': tokenRef.id,
        'rawPayload': payloadUrl,
        'rawToken': rawToken,
        'displayEmergencyId': displayEmergencyId,
        'expiresAt': expiresAt.toIso8601String(),
      };
    } catch (e, stackTrace) {
      SafeLogger.error('[TRACE_QR] ERROR in createEmergencyQr: $e', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> revokeEmergencyQr(String tokenId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not authenticated.');
    }

    try {
      _logger.i('Revoking Emergency QR tokenId: $tokenId');
      final docRef = _firestore.collection('emergency_qr_tokens').doc(tokenId);
      final docSnap = await docRef.get();

      if (!docSnap.exists || docSnap.data()?['ownerUserId'] != user.uid) {
        throw Exception('Unauthorized to revoke this QR code.');
      }

      await docRef.update({
        'status': 'revoked',
        'revokedAt': FieldValue.serverTimestamp(),
      });
    } catch (e, stackTrace) {
      _logger.e('Failed to revoke emergency QR token $tokenId', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> regenerateEmergencyQr() async {
    return createEmergencyQr();
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

  static Future<PublicEmergencyDto> resolveEmergencyQrDirect({
    required FirebaseFirestore firestore,
    required String inputToken,
    String sourceType = 'camera',
  }) async {
    String rawToken = inputToken.trim();
    if (rawToken.contains('/emergency/')) {
      final parts = rawToken.split('/emergency/');
      rawToken = parts.last;
    } else if (rawToken.contains('/qr/')) {
      final parts = rawToken.split('/qr/');
      rawToken = parts.last;
    }

    QuerySnapshot snapshot;
    if (rawToken.startsWith('ST-')) {
      snapshot = await firestore
          .collection('emergency_qr_tokens')
          .where('displayEmergencyId', isEqualTo: rawToken)
          .where('status', isEqualTo: 'active')
          .limit(1)
          .get();
    } else {
      final bytes = utf8.encode(rawToken);
      final tokenHash = sha256.convert(bytes).toString();
      snapshot = await firestore
          .collection('emergency_qr_tokens')
          .where('tokenHash', isEqualTo: tokenHash)
          .where('status', isEqualTo: 'active')
          .limit(1)
          .get();
    }

    if (snapshot.docs.isEmpty) {
      throw Exception('invalid_token');
    }

    final tokenDoc = snapshot.docs.first;
    final tokenData = tokenDoc.data() as Map<String, dynamic>;

    if (tokenData['status'] == 'revoked') {
      throw Exception('revoked_token');
    }

    if (tokenData['status'] != 'active') {
      throw Exception('invalid_token');
    }

    final expiresAt = (tokenData['expiresAt'] as Timestamp?)?.toDate();
    if (expiresAt != null && expiresAt.isBefore(DateTime.now())) {
      throw Exception('expired_token');
    }

    final ownerUserId = tokenData['ownerUserId'] as String? ?? '';
    final profileDoc = await firestore.collection('medical_profiles').doc(ownerUserId).get();

    final profile = profileDoc.data() ?? {};

    if (profile['emergencyAccessEnabled'] == false) {
      throw Exception('unavailable');
    }

    List<Map<String, dynamic>> emergencyContacts = [];
    if (profile['shareEmergencyContactsInEmergency'] != false &&
        profile['shareContactsInEmergency'] != false) {
      final contactsSnapshot = await firestore
          .collection('users')
          .doc(ownerUserId)
          .collection('emergency_contacts')
          .orderBy('priority', descending: false)
          .limit(5)
          .get();

      emergencyContacts = contactsSnapshot.docs.map((cDoc) {
        final cData = cDoc.data();
        return {
          'id': cDoc.id,
          'name': cData['name'] ?? '',
          'relationship': cData['relationship'] ?? '',
          'phoneNumber': cData['phoneNumber'] ?? '',
        };
      }).toList();
    }

    tokenDoc.reference.update({
      'scanCount': FieldValue.increment(1),
      'lastScannedAt': FieldValue.serverTimestamp(),
    });

    return PublicEmergencyDto.fromMap({
      'displayEmergencyId': tokenData['displayEmergencyId'] as String? ?? 'ST-0000-0000',
      'fullName': profile['shareNameInEmergency'] != false ? (profile['fullName'] as String? ?? 'Emergency Patient') : 'Emergency Patient',
      'photoUrl': profile['sharePhotoInEmergency'] == true ? profile['photoUrl'] as String? : null,
      'bloodGroup': profile['shareBloodGroupInEmergency'] != false ? (profile['bloodGroup'] as String? ?? 'Not Specified') : 'Restricted',
      'allergies': profile['shareAllergiesInEmergency'] != false ? (profile['allergies'] as String? ?? 'None reported') : 'Restricted',
      'medicalConditions': profile['shareMedicalConditionsInEmergency'] != false ? (profile['medicalConditions'] as String? ?? 'None reported') : 'Restricted',
      'currentMedications': profile['shareMedicationsInEmergency'] != false ? (profile['currentMedications'] as String? ?? 'None reported') : 'Restricted',
      'implants': profile['shareImplantsInEmergency'] != false ? (profile['implants'] as String? ?? 'None reported') : 'Restricted',
      'emergencyNotes': profile['shareEmergencyNotesInEmergency'] != false ? (profile['notes'] as String? ?? '') : 'Restricted',
      'primaryDoctor': profile['shareDoctorHospitalInEmergency'] != false ? profile['primaryDoctor'] as String? : null,
      'preferredHospital': profile['shareDoctorHospitalInEmergency'] != false ? profile['preferredHospital'] as String? : null,
      'hospitalAddress': profile['shareDoctorHospitalInEmergency'] != false && profile['shareHospitalDirectionsInEmergency'] != false ? profile['hospitalAddress'] as String? : null,
      'emergencyContacts': emergencyContacts,
      'lastUpdated': profile['lastEmergencyProfileUpdateAt'] != null
          ? (profile['lastEmergencyProfileUpdateAt'] is Timestamp
              ? (profile['lastEmergencyProfileUpdateAt'] as Timestamp).toDate().toIso8601String()
              : profile['lastEmergencyProfileUpdateAt'].toString())
          : null,
    });
  }
}
