import 'dart:convert';

class MedicalProfile {
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

  const MedicalProfile({
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

  Map<String, dynamic> toMap() {
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

  factory MedicalProfile.fromMap(Map<String, dynamic> map) {
    return MedicalProfile(
      uid: map['uid'] as String? ?? '',
      photoUrl: map['photoUrl'] as String?,
      fullName: map['fullName'] as String? ?? '',
      age: map['age'] as int? ?? 0,
      gender: map['gender'] as String? ?? '',
      bloodGroup: map['bloodGroup'] as String? ?? '',
      heightCm: (map['heightCm'] as num?)?.toDouble() ?? 0.0,
      weightKg: (map['weightKg'] as num?)?.toDouble() ?? 0.0,
      medicalConditions: map['medicalConditions'] as String? ?? '',
      allergies: map['allergies'] as String? ?? '',
      currentMedications: map['currentMedications'] as String? ?? '',
      pastSurgeries: map['pastSurgeries'] as String? ?? '',
      implants: map['implants'] as String? ?? '',
      isPregnant: map['isPregnant'] as bool? ?? false,
      isOrganDonor: map['isOrganDonor'] as bool? ?? false,
      insuranceInfo: map['insuranceInfo'] as String? ?? '',
      primaryDoctor: map['primaryDoctor'] as String? ?? '',
      preferredHospital: map['preferredHospital'] as String? ?? '',
      notes: map['notes'] as String? ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory MedicalProfile.fromJson(String source) => MedicalProfile.fromMap(json.decode(source) as Map<String, dynamic>);
}
