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

    SafeLogger.info('[MEDICAL_PROFILE_DEBUG] uid=$uid getProfile started, path=$path');

    if (uid.isEmpty) {
      SafeLogger.info('[MEDICAL_PROFILE_DEBUG] uid is empty, returning null');
      return null;
    }

    DocumentSnapshot<Map<String, dynamic>>? doc;
    Object? serverError;

    try {
      doc = await _firestore
          .collection('medical_profiles')
          .doc(uid)
          .get()
          .timeout(const Duration(seconds: 15));

      SafeLogger.info(
        '[MEDICAL_PROFILE_DEBUG] Firestore doc fetch completed. exists=${doc.exists}',
      );
    } catch (e, st) {
      serverError = e;
      SafeLogger.info(
        '[MEDICAL_PROFILE_DEBUG] Firestore doc fetch error/timeout: $e',
      );
    }

    if (doc == null || !doc.exists) {
      try {
        final cacheDoc = await _firestore
            .collection('medical_profiles')
            .doc(uid)
            .get(const GetOptions(source: Source.cache));

        if (cacheDoc.exists) {
          doc = cacheDoc;
          SafeLogger.info(
            '[MEDICAL_PROFILE_DEBUG] Firestore cache source doc retrieved. exists=true',
          );
        }
      } catch (cacheErr) {
        SafeLogger.info(
          '[MEDICAL_PROFILE_DEBUG] Firestore cache source doc fetch failed: $cacheErr',
        );
      }
    }

    if (doc != null && doc.exists && doc.data() != null) {
      final data = doc.data()!;
      SafeLogger.info(
        '[MEDICAL_PROFILE_DEBUG] DOCUMENT EXISTS = true, keys=${data.keys.toList()}',
      );

      try {
        final profile = MedicalProfile.fromMap(data);
        SafeLogger.info(
          '[MEDICAL_PROFILE_DEBUG] Deserialization successful for uid=$uid, fullName="${profile.fullName}"',
        );
        await _cacheService.cacheProfile(profile);
        return profile;
      } catch (e, st) {
        SafeLogger.error(
          '[MEDICAL_PROFILE_DEBUG] Deserialization error for uid=$uid: $e',
          error: e,
          stackTrace: st,
        );
        rethrow;
      }
    }

    if (serverError != null) {
      final cached = _cacheService.getCachedProfile(uid);
      if (cached != null) {
        SafeLogger.info(
          '[MEDICAL_PROFILE_DEBUG] Returning SharedPreferences cached profile fallback for uid=$uid: "${cached.fullName}"',
        );
        return cached;
      }
      SafeLogger.info('[MEDICAL_PROFILE_DEBUG] Re-throwing server error for uid=$uid: $serverError');
      throw serverError;
    }

    SafeLogger.info('[MEDICAL_PROFILE_DEBUG] Document clean 404 (does not exist on Firestore) for uid=$uid');
    return null;
  }

  @override
  Future<void> saveProfile(MedicalProfile profile) async {
    final path = 'medical_profiles/${profile.uid}';

    SafeLogger.info('[MEDICAL_PROFILE_DEBUG] uid=${profile.uid} save started, path=$path');

    if (profile.uid.isEmpty) {
      throw Exception('Cannot save profile with an empty User ID.');
    }

    final map = profile.toMap();

    SafeLogger.info(
      '[MEDICAL_PROFILE_DEBUG] save payload keys=${map.keys.toList()}, fullName="${map['fullName']}", age=${map['age']}',
    );

    try {
      await _firestore
          .collection('medical_profiles')
          .doc(profile.uid)
          .set(map, SetOptions(merge: true))
          .timeout(const Duration(seconds: 15));

      SafeLogger.info('[MEDICAL_PROFILE_DEBUG] uid=${profile.uid} Firestore write completed successfully');

      try {
        await _cacheService
            .cacheProfile(profile)
            .timeout(const Duration(seconds: 5));
        SafeLogger.info('[MEDICAL_PROFILE_DEBUG] uid=${profile.uid} SharedPreferences cache write completed');
      } catch (cacheError) {
        SafeLogger.warn(
          '[MEDICAL_PROFILE_DEBUG] SharedPreferences cache write failed, continuing: $cacheError',
        );
      }

      SafeLogger.info('[MEDICAL_PROFILE_DEBUG] uid=${profile.uid} save completed');
    } catch (e, st) {
      SafeLogger.error(
        '[MEDICAL_PROFILE_DEBUG] uid=${profile.uid} save failed: $e',
        error: e,
        stackTrace: st,
      );

      throw Exception(
        'Unable to save profile. Please check your connection and try again.',
      );
    }
  }

  @override
  Future<String?> uploadProfilePhoto(
    String uid,
    File imageFile,
  ) async {
    SafeLogger.info('[MEDICAL_PROFILE_DEBUG] uid=$uid photo upload started');
    try {
      final storageRef = _storage
          .ref()
          .child('medical_profiles')
          .child(uid)
          .child('profile_photo.jpg');

      final uploadTask = storageRef.putFile(imageFile);
      final snapshot = await uploadTask.timeout(const Duration(seconds: 25));
      final downloadUrl = await snapshot.ref.getDownloadURL().timeout(const Duration(seconds: 10));

      SafeLogger.info('[MEDICAL_PROFILE_DEBUG] uid=$uid photo upload completed successfully');
      return downloadUrl;
    } catch (e, st) {
      SafeLogger.error(
        '[MEDICAL_PROFILE_DEBUG] uid=$uid photo upload failed: $e',
        error: e,
        stackTrace: st,
      );

      throw Exception(
        'Failed to upload profile photo. Please try again.',
      );
    }
  }
}