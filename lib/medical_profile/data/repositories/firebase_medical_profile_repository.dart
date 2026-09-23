import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:sozotap/core/logging/safe_logger.dart';

import '../../domain/models/medical_profile.dart';
import '../../domain/repositories/medical_profile_repository.dart';
import '../services/medical_profile_cache_service.dart';
import '../../../utils/logger.dart';

class FirebaseMedicalProfileRepository
    implements MedicalProfileRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final MedicalProfileCacheService _cacheService;

  FirebaseMedicalProfileRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    required MedicalProfileCacheService cacheService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance,
        _cacheService = cacheService;

  @override
  Future<MedicalProfile?> getProfile(String uid) async {
    final path = 'medical_profiles/$uid';

    SafeLogger.info('[MEDICAL_DEBUG] AUTH UID = $uid');
    SafeLogger.info('[MEDICAL_DEBUG] FIRESTORE PATH = $path');
    SafeLogger.info('[MEDICAL_DEBUG] FIRESTORE READ START');

    DocumentSnapshot<Map<String, dynamic>>? doc;
    Object? serverError;

    SafeLogger.info('[MEDICAL_DEBUG] SERVER READ ATTEMPT START');

    try {
      doc = await _firestore
          .collection('medical_profiles')
          .doc(uid)
          .get(
            const GetOptions(source: Source.server),
          )
          .timeout(const Duration(seconds: 5));

      SafeLogger.info(
        '[MEDICAL_DEBUG] SERVER READ COMPLETED SUCCESS. '
        'doc.exists = ${doc.exists}',
      );
    } catch (e, st) {
      serverError = e;

      SafeLogger.info(
        '[MEDICAL_DEBUG] SERVER READ FAILED/TIMED OUT: $e',
      );

      SafeLogger.info(
        '[MEDICAL_DEBUG] SERVER READ EXCEPTION STACK: $st',
      );
    }

    if (doc == null || !doc.exists) {
      SafeLogger.info('[MEDICAL_DEBUG] CACHE READ ATTEMPT START');

      try {
        final cacheDoc = await _firestore
            .collection('medical_profiles')
            .doc(uid)
            .get(
              const GetOptions(source: Source.cache),
            );

        SafeLogger.info(
          '[MEDICAL_DEBUG] CACHE READ COMPLETED. '
          'cacheDoc.exists = ${cacheDoc.exists}',
        );

        if (cacheDoc.exists) {
          doc = cacheDoc;
        }
      } catch (e) {
        SafeLogger.info(
          '[MEDICAL_DEBUG] CACHE READ FAILED/EMPTY: $e',
        );
      }
    }

    if (doc != null && doc.exists && doc.data() != null) {
      final data = doc.data()!;

      SafeLogger.info('[MEDICAL_DEBUG] FIRESTORE READ COMPLETED');
      SafeLogger.info('[MEDICAL_DEBUG] DOCUMENT EXISTS = true');
      SafeLogger.info(
        '[MEDICAL_DEBUG] DOCUMENT DATA KEYS = ${data.keys.toList()}',
      );
      SafeLogger.info(
        '[MEDICAL_DEBUG] FULLNAME = "${data['fullName']}"',
      );
      SafeLogger.info(
        '[MEDICAL_DEBUG] AGE = ${data['age']}',
      );
      SafeLogger.info(
        '[MEDICAL_DEBUG] GENDER = "${data['gender']}"',
      );
      SafeLogger.info(
        '[MEDICAL_DEBUG] BLOOD_GROUP = "${data['bloodGroup']}"',
      );

      SafeLogger.info('[MEDICAL_DEBUG] DESERIALIZATION START');

      try {
        final profile = MedicalProfile.fromMap(data);

        SafeLogger.info(
          '[MEDICAL_DEBUG] DESERIALIZATION SUCCESS: '
          'MedicalProfile(uid: ${profile.uid}, '
          'fullName: "${profile.fullName}")',
        );

        await _cacheService.cacheProfile(profile);

        return profile;
      } catch (e, st) {
        SafeLogger.info(
          '[MEDICAL_DEBUG] DESERIALIZATION ERROR: $e',
        );

        SafeLogger.info(
          '[MEDICAL_DEBUG] DESERIALIZATION ERROR STACK: $st',
        );

        rethrow;
      }
    } else {
      SafeLogger.info('[MEDICAL_DEBUG] FIRESTORE READ COMPLETED');
      SafeLogger.info('[MEDICAL_DEBUG] DOCUMENT EXISTS = false');
    }

    if (serverError != null) {
      SafeLogger.info(
        '[MEDICAL_DEBUG] RE-THROWING SERVER READ EXCEPTION '
        'TO PROVIDER: $serverError',
      );

      final cached = _cacheService.getCachedProfile(uid);

      if (cached != null) {
        SafeLogger.info(
          '[MEDICAL_DEBUG] RETURNING SHAREDPREFS CACHED PROFILE '
          'AS FALLBACK: "${cached.fullName}"',
        );

        return cached;
      }

      throw serverError;
    }

    return null;
  }

  @override
  Future<void> saveProfile(MedicalProfile profile) async {
    final path = 'medical_profiles/${profile.uid}';

    SafeLogger.info('[MEDICAL_DEBUG] SAVE START');
    SafeLogger.info(
      '[MEDICAL_DEBUG] SAVE FIRESTORE PATH = $path',
    );

    final map = profile.toMap();

    SafeLogger.info(
      '[MEDICAL_DEBUG] SAVE DATA KEYS = ${map.keys.toList()}',
    );
    SafeLogger.info(
      '[MEDICAL_DEBUG] SAVE FULLNAME = "${map['fullName']}"',
    );
    SafeLogger.info(
      '[MEDICAL_DEBUG] SAVE AGE = ${map['age']}',
    );
    SafeLogger.info(
      '[MEDICAL_DEBUG] SAVE GENDER = "${map['gender']}"',
    );
    SafeLogger.info(
      '[MEDICAL_DEBUG] SAVE BLOOD_GROUP = "${map['bloodGroup']}"',
    );

    try {
      SafeLogger.info(
        '[MEDICAL_DEBUG] FIRESTORE WRITE START',
      );

      await _firestore
          .collection('medical_profiles')
          .doc(profile.uid)
          .set(
            map,
            SetOptions(merge: true),
          )
          .timeout(const Duration(seconds: 10));

      SafeLogger.info(
        '[MEDICAL_DEBUG] FIRESTORE WRITE SUCCESS',
      );

      try {
        SafeLogger.info(
          '[MEDICAL_DEBUG] CACHE WRITE START',
        );

        await _cacheService
            .cacheProfile(profile)
            .timeout(const Duration(seconds: 5));

        SafeLogger.info(
          '[MEDICAL_DEBUG] CACHE WRITE SUCCESS',
        );
      } catch (cacheError, cacheStack) {
        SafeLogger.error(
          '[MEDICAL_DEBUG] CACHE WRITE FAILED - '
          'continuing because Firestore succeeded',
          error: cacheError,
          stackTrace: cacheStack,
        );
      }

      SafeLogger.info(
        '[MEDICAL_DEBUG] SAVE COMPLETED SUCCESSFULLY',
      );
    } catch (e, st) {
      SafeLogger.error(
        '[MEDICAL_DEBUG] FIRESTORE SAVE FAILED',
        error: e,
        stackTrace: st,
      );

      throw Exception(
        'Failed to save profile. Please check your connection.',
      );
    }
  }

  @override
  Future<String?> uploadProfilePhoto(
    String uid,
    File imageFile,
  ) async {
    try {
      final ref = _storage
          .ref()
          .child('medical_profiles')
          .child(uid)
          .child('profile_photo.jpg');

      final uploadTask = await ref
          .putFile(imageFile)
          .timeout(const Duration(seconds: 30));

      return await uploadTask.ref.getDownloadURL();
    } catch (e, st) {
      AppLogger.e(
        'Failed to upload photo',
        e,
        st,
      );

      throw Exception(
        'Failed to upload photo. Please try again.',
      );
    }
  }
}