import '../models/medical_profile.dart';
import '../repositories/medical_profile_repository.dart';

class GetMedicalProfile {
  final MedicalProfileRepository repository;

  GetMedicalProfile(this.repository);

  Future<MedicalProfile?> call(String uid) {
    return repository.getProfile(uid);
  }
}
