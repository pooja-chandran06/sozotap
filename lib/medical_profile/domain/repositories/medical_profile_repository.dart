import 'dart:io';
import '../models/medical_profile.dart';

abstract class MedicalProfileRepository {
  Future<MedicalProfile?> getProfile(String uid);
  Future<void> saveProfile(MedicalProfile profile);
  Future<String?> uploadProfilePhoto(String uid, File imageFile);
}
