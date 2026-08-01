import '../models/medical_profile.dart';

// MOCK: Interface requested by prompt, real implementation exists in medical profile module
abstract class MedicalProfileReadRepository {
  Future<MedicalProfile?> getProfile(String uid);
}
