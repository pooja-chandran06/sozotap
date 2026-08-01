import '../../domain/models/medical_profile.dart';

class MedicalProfileDto {
  final String uid;
  final String? photoUrl;
  final String fullName;
  final int age;
  final String gender;
  final String bloodGroup;
  final double heightCm;
  final double weightKg;
  final String medicalConditions;
  final String allergies;
  final String currentMedications;
  final String pastSurgeries;
  final String implants;
  final bool isPregnant;
  final bool isOrganDonor;
  final String insuranceInfo;
  final String primaryDoctor;
  final String preferredHospital;
  final String notes;

  const MedicalProfileDto({
    required this.uid,
    this.photoUrl,
    required this.fullName,
    required this.age,
    required this.gender,
    required this.bloodGroup,
    required this.heightCm,
    required this.weightKg,
    required this.medicalConditions,
    required this.allergies,
    required this.currentMedications,
    required this.pastSurgeries,
    required this.implants,
    required this.isPregnant,
    required this.isOrganDonor,
    required this.insuranceInfo,
    required this.primaryDoctor,
    required this.preferredHospital,
    required this.notes,
  });

  factory MedicalProfileDto.fromDomain(MedicalProfile profile) {
    return MedicalProfileDto(
      uid: profile.uid,
      photoUrl: profile.photoUrl,
      fullName: profile.fullName,
      age: profile.age,
      gender: profile.gender,
      bloodGroup: profile.bloodGroup,
      heightCm: profile.heightCm,
      weightKg: profile.weightKg,
      medicalConditions: profile.medicalConditions,
      allergies: profile.allergies,
      currentMedications: profile.currentMedications,
      pastSurgeries: profile.pastSurgeries,
      implants: profile.implants,
      isPregnant: profile.isPregnant,
      isOrganDonor: profile.isOrganDonor,
      insuranceInfo: profile.insuranceInfo,
      primaryDoctor: profile.primaryDoctor,
      preferredHospital: profile.preferredHospital,
      notes: profile.notes,
    );
  }

  MedicalProfile toDomain() {
    return MedicalProfile(
      uid: uid,
      photoUrl: photoUrl,
      fullName: fullName,
      age: age,
      gender: gender,
      bloodGroup: bloodGroup,
      heightCm: heightCm,
      weightKg: weightKg,
      medicalConditions: medicalConditions,
      allergies: allergies,
      currentMedications: currentMedications,
      pastSurgeries: pastSurgeries,
      implants: implants,
      isPregnant: isPregnant,
      isOrganDonor: isOrganDonor,
      insuranceInfo: insuranceInfo,
      primaryDoctor: primaryDoctor,
      preferredHospital: preferredHospital,
      notes: notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'photoUrl': photoUrl,
      'fullName': fullName,
      'age': age,
      'gender': gender,
      'bloodGroup': bloodGroup,
      'heightCm': heightCm,
      'weightKg': weightKg,
      'medicalConditions': medicalConditions,
      'allergies': allergies,
      'currentMedications': currentMedications,
      'pastSurgeries': pastSurgeries,
      'implants': implants,
      'isPregnant': isPregnant,
      'isOrganDonor': isOrganDonor,
      'insuranceInfo': insuranceInfo,
      'primaryDoctor': primaryDoctor,
      'preferredHospital': preferredHospital,
      'notes': notes,
    };
  }

  factory MedicalProfileDto.fromJson(Map<String, dynamic> json) {
    return MedicalProfileDto(
      uid: json['uid'] as String? ?? '',
      photoUrl: json['photoUrl'] as String?,
      fullName: json['fullName'] as String? ?? '',
      age: json['age'] as int? ?? 0,
      gender: json['gender'] as String? ?? '',
      bloodGroup: json['bloodGroup'] as String? ?? '',
      heightCm: (json['heightCm'] as num?)?.toDouble() ?? 0.0,
      weightKg: (json['weightKg'] as num?)?.toDouble() ?? 0.0,
      medicalConditions: json['medicalConditions'] as String? ?? '',
      allergies: json['allergies'] as String? ?? '',
      currentMedications: json['currentMedications'] as String? ?? '',
      pastSurgeries: json['pastSurgeries'] as String? ?? '',
      implants: json['implants'] as String? ?? '',
      isPregnant: json['isPregnant'] as bool? ?? false,
      isOrganDonor: json['isOrganDonor'] as bool? ?? false,
      insuranceInfo: json['insuranceInfo'] as String? ?? '',
      primaryDoctor: json['primaryDoctor'] as String? ?? '',
      preferredHospital: json['preferredHospital'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
    );
  }
}
