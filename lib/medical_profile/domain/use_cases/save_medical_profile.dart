import '../models/medical_profile.dart';
import '../repositories/medical_profile_repository.dart';

class SaveMedicalProfile {
  final MedicalProfileRepository repository;

  SaveMedicalProfile(this.repository);

  Future<void> call(MedicalProfile profile) {
    return repository.saveProfile(profile);
  }
}
