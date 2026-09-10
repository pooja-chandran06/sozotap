import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  // Emergency Visibility Consent Controls
  final bool emergencyAccessEnabled;
  final bool sharePhotoInEmergency;
  final bool shareNameInEmergency;
  final bool shareDoctorHospitalInEmergency;
  final bool shareContactsInEmergency;
  final bool shareDirectionsInEmergency;
  final String? hospitalAddress;
  final int emergencyVisibleFieldsVersion;
  final DateTime? lastEmergencyProfileUpdateAt;

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
    this.emergencyAccessEnabled = true,
    this.sharePhotoInEmergency = false,
    this.shareNameInEmergency = true,
    this.shareDoctorHospitalInEmergency = true,
    this.shareContactsInEmergency = true,
    this.shareDirectionsInEmergency = true,
    this.hospitalAddress,
    this.emergencyVisibleFieldsVersion = 1,
    this.lastEmergencyProfileUpdateAt,
  });

  MedicalProfile copyWith({
    String? uid,
    String? photoUrl,
    String? fullName,
    int? age,
    String? gender,
    String? bloodGroup,
    double? heightCm,
    double? weightKg,
    String? medicalConditions,
    String? allergies,
    String? currentMedications,
    String? pastSurgeries,
    String? implants,
    bool? isPregnant,
    bool? isOrganDonor,
    String? insuranceInfo,
    String? primaryDoctor,
    String? preferredHospital,
    String? notes,
    bool? emergencyAccessEnabled,
    bool? sharePhotoInEmergency,
    bool? shareNameInEmergency,
    bool? shareDoctorHospitalInEmergency,
    bool? shareContactsInEmergency,
    bool? shareDirectionsInEmergency,
    String? hospitalAddress,
    int? emergencyVisibleFieldsVersion,
    DateTime? lastEmergencyProfileUpdateAt,
  }) {
    return MedicalProfile(
      uid: uid ?? this.uid,
      photoUrl: photoUrl ?? this.photoUrl,
      fullName: fullName ?? this.fullName,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      medicalConditions: medicalConditions ?? this.medicalConditions,
      allergies: allergies ?? this.allergies,
      currentMedications: currentMedications ?? this.currentMedications,
      pastSurgeries: pastSurgeries ?? this.pastSurgeries,
      implants: implants ?? this.implants,
      isPregnant: isPregnant ?? this.isPregnant,
      isOrganDonor: isOrganDonor ?? this.isOrganDonor,
      insuranceInfo: insuranceInfo ?? this.insuranceInfo,
      primaryDoctor: primaryDoctor ?? this.primaryDoctor,
      preferredHospital: preferredHospital ?? this.preferredHospital,
      notes: notes ?? this.notes,
      emergencyAccessEnabled: emergencyAccessEnabled ?? this.emergencyAccessEnabled,
      sharePhotoInEmergency: sharePhotoInEmergency ?? this.sharePhotoInEmergency,
      shareNameInEmergency: shareNameInEmergency ?? this.shareNameInEmergency,
      shareDoctorHospitalInEmergency: shareDoctorHospitalInEmergency ?? this.shareDoctorHospitalInEmergency,
      shareContactsInEmergency: shareContactsInEmergency ?? this.shareContactsInEmergency,
      shareDirectionsInEmergency: shareDirectionsInEmergency ?? this.shareDirectionsInEmergency,
      hospitalAddress: hospitalAddress ?? this.hospitalAddress,
      emergencyVisibleFieldsVersion: emergencyVisibleFieldsVersion ?? this.emergencyVisibleFieldsVersion,
      lastEmergencyProfileUpdateAt: lastEmergencyProfileUpdateAt ?? this.lastEmergencyProfileUpdateAt,
    );
  }

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
      'emergencyAccessEnabled': emergencyAccessEnabled,
      'sharePhotoInEmergency': sharePhotoInEmergency,
      'shareNameInEmergency': shareNameInEmergency,
      'shareDoctorHospitalInEmergency': shareDoctorHospitalInEmergency,
      'shareContactsInEmergency': shareContactsInEmergency,
      'shareDirectionsInEmergency': shareDirectionsInEmergency,
      'hospitalAddress': hospitalAddress,
      'emergencyVisibleFieldsVersion': emergencyVisibleFieldsVersion,
      'lastEmergencyProfileUpdateAt': lastEmergencyProfileUpdateAt != null
          ? Timestamp.fromDate(lastEmergencyProfileUpdateAt!)
          : null,
    };
  }

  factory MedicalProfile.fromMap(Map<String, dynamic> map) {
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    return MedicalProfile(
      uid: map['uid'] as String? ?? '',
      photoUrl: map['photoUrl'] as String?,
      fullName: map['fullName'] as String? ?? '',
      age: (map['age'] as num?)?.toInt() ?? 0,
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
      emergencyAccessEnabled: map['emergencyAccessEnabled'] as bool? ?? true,
      sharePhotoInEmergency: map['sharePhotoInEmergency'] as bool? ?? false,
      shareNameInEmergency: map['shareNameInEmergency'] as bool? ?? true,
      shareDoctorHospitalInEmergency: map['shareDoctorHospitalInEmergency'] as bool? ?? true,
      shareContactsInEmergency: map['shareContactsInEmergency'] as bool? ?? true,
      shareDirectionsInEmergency: map['shareDirectionsInEmergency'] as bool? ?? true,
      hospitalAddress: map['hospitalAddress'] as String?,
      emergencyVisibleFieldsVersion: (map['emergencyVisibleFieldsVersion'] as num?)?.toInt() ?? 1,
      lastEmergencyProfileUpdateAt: parseDate(map['lastEmergencyProfileUpdateAt']),
    );
  }

  String toJson() => json.encode(toMap());

  factory MedicalProfile.fromJson(String source) => MedicalProfile.fromMap(json.decode(source) as Map<String, dynamic>);
}
