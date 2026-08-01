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
    try {
      final doc = await _firestore.collection('medical_profiles').doc(uid).get().timeout(const Duration(seconds: 10));
      if (doc.exists && doc.data() != null) {
        final profile = MedicalProfile.fromMap(doc.data()!);
        await _cacheService.cacheProfile(profile);
        return profile;
      }
    } catch (e, st) {
      AppLogger.e('Failed to fetch profile from Firestore, falling back to cache', e, st);
    }
    return _cacheService.getCachedProfile(uid);
  }

  @override
  Future<void> saveProfile(MedicalProfile profile) async {
    try {
      await _firestore
          .collection('medical_profiles')
          .doc(profile.uid)
          .set(profile.toMap(), SetOptions(merge: true))
          .timeout(const Duration(seconds: 10));
      await _cacheService.cacheProfile(profile);
    } catch (e, st) {
      AppLogger.e('Failed to save profile', e, st);
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
