import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/medical_profile_dto.dart';

abstract class MedicalProfileRemoteDatasource {
  Future<MedicalProfileDto?> getProfile(String uid);
  Future<void> saveProfile(MedicalProfileDto dto);
  Future<String?> uploadProfilePhoto(String uid, File imageFile);
}

class MedicalProfileRemoteDatasourceImpl implements MedicalProfileRemoteDatasource {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  MedicalProfileRemoteDatasourceImpl({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  @override
  Future<MedicalProfileDto?> getProfile(String uid) async {
    final doc = await _firestore.collection('medical_profiles').doc(uid).get();
    if (doc.exists && doc.data() != null) {
      return MedicalProfileDto.fromJson(doc.data()!);
    }
    return null;
  }

  @override
  Future<void> saveProfile(MedicalProfileDto dto) async {
    await _firestore
        .collection('medical_profiles')
        .doc(dto.uid)
        .set(dto.toJson(), SetOptions(merge: true));
  }

  @override
  Future<String?> uploadProfilePhoto(String uid, File imageFile) async {
    final ref = _storage.ref().child('medical_profiles').child(uid).child('profile_photo.jpg');
    final uploadTask = await ref.putFile(imageFile);
    return await uploadTask.ref.getDownloadURL();
  }
}
