import '../../medical_profile/domain/models/medical_profile.dart';

class EmergencyPayloadBuilder {
  Map<String, dynamic> buildMinimalPayload(MedicalProfile profile) {
    return {
      'name': profile.fullName,
      'bloodGroup': profile.bloodGroup,
      'conditions': _extractTopItems(profile.medicalConditions, 3),
      'allergies': _extractTopItems(profile.allergies, 3),
      'medications': _extractTopItems(profile.currentMedications, 3),
      'doctorName': profile.primaryDoctor,
      'hospitalName': profile.preferredHospital,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  List<String> _extractTopItems(String commaSeparated, int limit) {
    if (commaSeparated.isEmpty) return [];
    return commaSeparated
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .take(limit)
        .toList();
  }
}
