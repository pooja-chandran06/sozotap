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

    int parseInt(dynamic val) {
      if (val == null) return 0;
      if (val is num) return val.toInt();
      if (val is String) return int.tryParse(val) ?? 0;
      return 0;
    }

    double parseDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val) ?? 0.0;
      return 0.0;
    }

    bool parseBool(dynamic val, {bool defaultValue = false}) {
      if (val == null) return defaultValue;
      if (val is bool) return val;
      if (val is String) {
        final lower = val.toLowerCase();
        if (lower == 'true' || lower == '1') return true;
        if (lower == 'false' || lower == '0') return false;
      }
      if (val is num) return val != 0;
      return defaultValue;
    }

    String parseString(dynamic val) {
      if (val == null) return '';
      return val.toString();
    }

    final emergencyVer = parseInt(map['emergencyVisibleFieldsVersion']);

    return MedicalProfile(
      uid: parseString(map['uid']),
      photoUrl: map['photoUrl'] as String?,
      fullName: parseString(map['fullName']),
      age: parseInt(map['age']),
      gender: parseString(map['gender']),
      bloodGroup: parseString(map['bloodGroup']),
      heightCm: parseDouble(map['heightCm']),
      weightKg: parseDouble(map['weightKg']),
      medicalConditions: parseString(map['medicalConditions']),
      allergies: parseString(map['allergies']),
      currentMedications: parseString(map['currentMedications']),
      pastSurgeries: parseString(map['pastSurgeries']),
      implants: parseString(map['implants']),
      isPregnant: parseBool(map['isPregnant'], defaultValue: false),
      isOrganDonor: parseBool(map['isOrganDonor'], defaultValue: false),
      insuranceInfo: parseString(map['insuranceInfo']),
      primaryDoctor: parseString(map['primaryDoctor']),
      preferredHospital: parseString(map['preferredHospital']),
      notes: parseString(map['notes']),
      emergencyAccessEnabled: parseBool(map['emergencyAccessEnabled'], defaultValue: true),
      sharePhotoInEmergency: parseBool(map['sharePhotoInEmergency'], defaultValue: false),
      shareNameInEmergency: parseBool(map['shareNameInEmergency'], defaultValue: true),
      shareDoctorHospitalInEmergency: parseBool(map['shareDoctorHospitalInEmergency'], defaultValue: true),
      shareContactsInEmergency: parseBool(map['shareContactsInEmergency'], defaultValue: true),
      shareDirectionsInEmergency: parseBool(map['shareDirectionsInEmergency'], defaultValue: true),
      hospitalAddress: map['hospitalAddress'] as String?,
      emergencyVisibleFieldsVersion: emergencyVer == 0 ? 1 : emergencyVer,
      lastEmergencyProfileUpdateAt: parseDate(map['lastEmergencyProfileUpdateAt']),
    );
  }

  Map<String, dynamic> toJsonMap() {
    final map = toMap();
    if (map['lastEmergencyProfileUpdateAt'] is Timestamp) {
      map['lastEmergencyProfileUpdateAt'] = (map['lastEmergencyProfileUpdateAt'] as Timestamp).toDate().toIso8601String();
    } else if (lastEmergencyProfileUpdateAt != null) {
      map['lastEmergencyProfileUpdateAt'] = lastEmergencyProfileUpdateAt!.toIso8601String();
    }
    return map;
  }

  String toJson() => json.encode(toJsonMap());

  factory MedicalProfile.fromJson(String source) => MedicalProfile.fromMap(json.decode(source) as Map<String, dynamic>);
}
