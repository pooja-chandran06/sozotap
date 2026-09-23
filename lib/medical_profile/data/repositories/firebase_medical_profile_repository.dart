import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../domain/models/medical_profile.dart';
import '../../domain/repositories/medical_profile_repository.dart';
import '../services/medical_profile_cache_service.dart';
import '../../../utils/logger.dart';

class FirebaseMedicalProfileRepository implements MedicalProfileRepository {
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
    SafeLogger.info('[FirebaseMedicalProfileRepository] READ starting for UID: $uid at path: $path');
    try {
      DocumentSnapshot<Map<String, dynamic>> doc;
      try {
        doc = await _firestore
            .collection('medical_profiles')
            .doc(uid)
            .get(const GetOptions(source: Source.serverAndCache))
            .timeout(const Duration(seconds: 6));
      } catch (e) {
        SafeLogger.warn('[FirebaseMedicalProfileRepository] Primary get() timed out or failed for $path, trying Firestore local disk cache', error: e);
        doc = await _firestore
            .collection('medical_profiles')
            .doc(uid)
            .get(const GetOptions(source: Source.cache));
      }

      SafeLogger.info('[FirebaseMedicalProfileRepository] Firestore get() returned. doc.exists: ${doc.exists}');
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        SafeLogger.info('[FirebaseMedicalProfileRepository] Document found at $path. Fields present: ${data.keys.toList()}');
        final profile = MedicalProfile.fromMap(data);
        SafeLogger.info('[FirebaseMedicalProfileRepository] Deserialization successful for $path. Name: "${profile.fullName}", Age: ${profile.age}');
        await _cacheService.cacheProfile(profile);
        return profile;
      }
      SafeLogger.info('[FirebaseMedicalProfileRepository] Document DOES NOT exist at $path in Firestore');
      return null;
    } catch (e, st) {
      SafeLogger.error('[FirebaseMedicalProfileRepository] Failed to fetch profile from Firestore at $path, checking SharedPreferences cache', error: e, stackTrace: st);
      final cached = _cacheService.getCachedProfile(uid);
      if (cached != null) {
        SafeLogger.info('[FirebaseMedicalProfileRepository] SharedPreferences cache hit for $path');
        return cached;
      }
      SafeLogger.error('[FirebaseMedicalProfileRepository] SharedPreferences cache miss for $path. Rethrowing error');
      rethrow;
    }
  }

  @override
  Future<void> saveProfile(MedicalProfile profile) async {
    final path = 'medical_profiles/${profile.uid}';
    SafeLogger.info('[FirebaseMedicalProfileRepository] SAVE starting for UID: ${profile.uid} at path: $path');
    try {
      final map = profile.toMap();
      SafeLogger.info('[FirebaseMedicalProfileRepository] Saving fields to $path: ${map.keys.toList()}');
      await _firestore
          .collection('medical_profiles')
          .doc(profile.uid)
          .set(map, SetOptions(merge: true))
          .timeout(const Duration(seconds: 10));
      SafeLogger.info('[FirebaseMedicalProfileRepository] Firestore set() SUCCEEDED for $path');
      await _cacheService.cacheProfile(profile);
      SafeLogger.info('[FirebaseMedicalProfileRepository] SharedPreferences cacheProfile SUCCEEDED for $path');
    } catch (e, st) {
      SafeLogger.error('[FirebaseMedicalProfileRepository] Failed to save profile at $path', error: e, stackTrace: st);
      throw Exception('Failed to save profile. Please check your connection.');
    }
  }

  @override
  Future<String?> uploadProfilePhoto(String uid, File imageFile) async {
    try {
      final ref = _storage.ref().child('medical_profiles').child(uid).child('profile_photo.jpg');
      final uploadTask = await ref.putFile(imageFile).timeout(const Duration(seconds: 30));
      return await uploadTask.ref.getDownloadURL();
    } catch (e, st) {
      AppLogger.e('Failed to upload photo', e, st);
      throw Exception('Failed to upload photo. Please try again.');
    }
  }
}
