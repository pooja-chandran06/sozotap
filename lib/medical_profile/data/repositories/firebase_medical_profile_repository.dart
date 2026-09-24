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

    SafeLogger.info('[TRACE_MP] getProfile START uid=$uid path=$path');

    if (uid.isEmpty) {
      SafeLogger.info('[TRACE_MP] getProfile END uid=$uid (empty UID)');
      return null;
    }

    DocumentSnapshot<Map<String, dynamic>>? doc;
    Object? serverError;

    try {
      SafeLogger.info('[TRACE_MP] FIRESTORE_GET_START uid=$uid');
      doc = await _firestore
          .collection('medical_profiles')
          .doc(uid)
          .get()
          .timeout(const Duration(seconds: 15));
      SafeLogger.info('[TRACE_MP] FIRESTORE_GET_END uid=$uid docExists=${doc.exists}');
    } catch (e, st) {
      serverError = e;
      SafeLogger.info('[TRACE_MP] FIRESTORE_GET_ERROR uid=$uid error=$e');
    }

    if (doc == null || !doc.exists) {
      try {
        SafeLogger.info('[TRACE_MP] FIRESTORE_CACHE_GET_START uid=$uid');
        final cacheDoc = await _firestore
            .collection('medical_profiles')
            .doc(uid)
            .get(const GetOptions(source: Source.cache));
        SafeLogger.info('[TRACE_MP] FIRESTORE_CACHE_GET_END uid=$uid cacheDocExists=${cacheDoc.exists}');

        if (cacheDoc.exists) {
          doc = cacheDoc;
        }
      } catch (cacheErr) {
        SafeLogger.info('[TRACE_MP] FIRESTORE_CACHE_GET_ERROR uid=$uid error=$cacheErr');
      }
    }

    if (doc != null && doc.exists && doc.data() != null) {
      final data = doc.data()!;
      try {
        final profile = MedicalProfile.fromMap(data);
        SafeLogger.info('[TRACE_MP] DESERIALIZE_SUCCESS uid=$uid fullName="${profile.fullName}"');
        await _cacheService.cacheProfile(profile);
        SafeLogger.info('[TRACE_MP] getProfile END uid=$uid (doc loaded)');
        return profile;
      } catch (e, st) {
        SafeLogger.error('[TRACE_MP] DESERIALIZE_ERROR uid=$uid error=$e', error: e, stackTrace: st);
        rethrow;
      }
    }

    if (serverError != null) {
      final cached = _cacheService.getCachedProfile(uid);
      if (cached != null) {
        SafeLogger.info('[TRACE_MP] getProfile END uid=$uid (fallback to SP cache)');
        return cached;
      }
      SafeLogger.info('[TRACE_MP] getProfile ERROR uid=$uid rethrowing error=$serverError');
      throw serverError;
    }

    SafeLogger.info('[TRACE_MP] getProfile END uid=$uid (clean 404)');
    return null;
  }

  @override
  Future<void> saveProfile(MedicalProfile profile) async {
    final path = 'medical_profiles/${profile.uid}';

    SafeLogger.info('[TRACE_SAVE] FIRESTORE_START uid=${profile.uid} path=$path');

    if (profile.uid.isEmpty) {
      throw Exception('Cannot save profile with an empty User ID.');
    }

    final map = profile.toMap();

    try {
      await _firestore
          .collection('medical_profiles')
          .doc(profile.uid)
          .set(map, SetOptions(merge: true))
          .timeout(const Duration(seconds: 15));
      SafeLogger.info('[TRACE_SAVE] FIRESTORE_END uid=${profile.uid}');

      try {
        SafeLogger.info('[TRACE_SAVE] CACHE_START uid=${profile.uid}');
        await _cacheService
            .cacheProfile(profile)
            .timeout(const Duration(seconds: 5));
        SafeLogger.info('[TRACE_SAVE] CACHE_END uid=${profile.uid}');
      } catch (cacheError) {
        SafeLogger.info('[TRACE_SAVE] CACHE_ERROR uid=${profile.uid} error=$cacheError');
      }

      SafeLogger.info('[TRACE_SAVE] REPOSITORY_SAVE_COMPLETE uid=${profile.uid}');
    } catch (e, st) {
      SafeLogger.error('[TRACE_SAVE] FIRESTORE_SAVE_ERROR uid=${profile.uid} error=$e', error: e, stackTrace: st);
      throw Exception('Unable to save profile. Please check your connection and try again.');
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