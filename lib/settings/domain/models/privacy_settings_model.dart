import 'package:cloud_firestore/cloud_firestore.dart';

class PrivacySettingsModel {
  final bool emergencyAccessEnabled;
  final bool shareNameInEmergency;
  final bool sharePhotoInEmergency;
  final bool shareBloodGroupInEmergency;
  final bool shareAllergiesInEmergency;
  final bool shareMedicalConditionsInEmergency;
  final bool shareMedicationsInEmergency;
  final bool shareImplantsInEmergency;
  final bool shareDoctorHospitalInEmergency;
  final bool shareEmergencyContactsInEmergency;
  final bool shareHospitalDirectionsInEmergency;
  final bool shareEmergencyNotesInEmergency;
  final bool qrScanAlertEnabled;
  final bool sosLiveLocationSharingEnabled;
  final DateTime updatedAt;

  PrivacySettingsModel({
    this.emergencyAccessEnabled = true,
    this.shareNameInEmergency = true,
    this.sharePhotoInEmergency = false,
    this.shareBloodGroupInEmergency = true,
    this.shareAllergiesInEmergency = true,
    this.shareMedicalConditionsInEmergency = true,
    this.shareMedicationsInEmergency = true,
    this.shareImplantsInEmergency = true,
    this.shareDoctorHospitalInEmergency = true,
    this.shareEmergencyContactsInEmergency = true,
    this.shareHospitalDirectionsInEmergency = true,
    this.shareEmergencyNotesInEmergency = true,
    this.qrScanAlertEnabled = true,
    this.sosLiveLocationSharingEnabled = true,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  factory PrivacySettingsModel.recommendedPreset() {
    return PrivacySettingsModel(
      emergencyAccessEnabled: true,
      shareNameInEmergency: true,
      sharePhotoInEmergency: false,
      shareBloodGroupInEmergency: true,
      shareAllergiesInEmergency: true,
      shareMedicalConditionsInEmergency: true,
      shareMedicationsInEmergency: true,
      shareImplantsInEmergency: true,
      shareDoctorHospitalInEmergency: true,
      shareEmergencyContactsInEmergency: true,
      shareHospitalDirectionsInEmergency: true,
      shareEmergencyNotesInEmergency: true,
      qrScanAlertEnabled: true,
      sosLiveLocationSharingEnabled: true,
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'emergencyAccessEnabled': emergencyAccessEnabled,
      'shareNameInEmergency': shareNameInEmergency,
      'sharePhotoInEmergency': sharePhotoInEmergency,
      'shareBloodGroupInEmergency': shareBloodGroupInEmergency,
      'shareAllergiesInEmergency': shareAllergiesInEmergency,
      'shareMedicalConditionsInEmergency': shareMedicalConditionsInEmergency,
      'shareMedicationsInEmergency': shareMedicationsInEmergency,
      'shareImplantsInEmergency': shareImplantsInEmergency,
      'shareDoctorHospitalInEmergency': shareDoctorHospitalInEmergency,
      'shareEmergencyContactsInEmergency': shareEmergencyContactsInEmergency,
      'shareHospitalDirectionsInEmergency': shareHospitalDirectionsInEmergency,
      'shareEmergencyNotesInEmergency': shareEmergencyNotesInEmergency,
      'qrScanAlertEnabled': qrScanAlertEnabled,
      'sosLiveLocationSharingEnabled': sosLiveLocationSharingEnabled,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory PrivacySettingsModel.fromMap(Map<String, dynamic>? map) {
    if (map == null) return PrivacySettingsModel.recommendedPreset();
    return PrivacySettingsModel(
      emergencyAccessEnabled: map['emergencyAccessEnabled'] ?? true,
      shareNameInEmergency: map['shareNameInEmergency'] ?? true,
      sharePhotoInEmergency: map['sharePhotoInEmergency'] ?? false,
      shareBloodGroupInEmergency: map['shareBloodGroupInEmergency'] ?? true,
      shareAllergiesInEmergency: map['shareAllergiesInEmergency'] ?? true,
      shareMedicalConditionsInEmergency: map['shareMedicalConditionsInEmergency'] ?? true,
      shareMedicationsInEmergency: map['shareMedicationsInEmergency'] ?? true,
      shareImplantsInEmergency: map['shareImplantsInEmergency'] ?? true,
      shareDoctorHospitalInEmergency: map['shareDoctorHospitalInEmergency'] ?? true,
      shareEmergencyContactsInEmergency: map['shareEmergencyContactsInEmergency'] ?? true,
      shareHospitalDirectionsInEmergency: map['shareHospitalDirectionsInEmergency'] ?? true,
      shareEmergencyNotesInEmergency: map['shareEmergencyNotesInEmergency'] ?? true,
      qrScanAlertEnabled: map['qrScanAlertEnabled'] ?? true,
      sosLiveLocationSharingEnabled: map['sosLiveLocationSharingEnabled'] ?? true,
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  PrivacySettingsModel copyWith({
    bool? emergencyAccessEnabled,
    bool? shareNameInEmergency,
    bool? sharePhotoInEmergency,
    bool? shareBloodGroupInEmergency,
    bool? shareAllergiesInEmergency,
    bool? shareMedicalConditionsInEmergency,
    bool? shareMedicationsInEmergency,
    bool? shareImplantsInEmergency,
    bool? shareDoctorHospitalInEmergency,
    bool? shareEmergencyContactsInEmergency,
    bool? shareHospitalDirectionsInEmergency,
    bool? shareEmergencyNotesInEmergency,
    bool? qrScanAlertEnabled,
    bool? sosLiveLocationSharingEnabled,
    DateTime? updatedAt,
  }) {
    return PrivacySettingsModel(
      emergencyAccessEnabled: emergencyAccessEnabled ?? this.emergencyAccessEnabled,
      shareNameInEmergency: shareNameInEmergency ?? this.shareNameInEmergency,
      sharePhotoInEmergency: sharePhotoInEmergency ?? this.sharePhotoInEmergency,
      shareBloodGroupInEmergency: shareBloodGroupInEmergency ?? this.shareBloodGroupInEmergency,
      shareAllergiesInEmergency: shareAllergiesInEmergency ?? this.shareAllergiesInEmergency,
      shareMedicalConditionsInEmergency: shareMedicalConditionsInEmergency ?? this.shareMedicalConditionsInEmergency,
      shareMedicationsInEmergency: shareMedicationsInEmergency ?? this.shareMedicationsInEmergency,
      shareImplantsInEmergency: shareImplantsInEmergency ?? this.shareImplantsInEmergency,
      shareDoctorHospitalInEmergency: shareDoctorHospitalInEmergency ?? this.shareDoctorHospitalInEmergency,
      shareEmergencyContactsInEmergency: shareEmergencyContactsInEmergency ?? this.shareEmergencyContactsInEmergency,
      shareHospitalDirectionsInEmergency: shareHospitalDirectionsInEmergency ?? this.shareHospitalDirectionsInEmergency,
      shareEmergencyNotesInEmergency: shareEmergencyNotesInEmergency ?? this.shareEmergencyNotesInEmergency,
      qrScanAlertEnabled: qrScanAlertEnabled ?? this.qrScanAlertEnabled,
      sosLiveLocationSharingEnabled: sosLiveLocationSharingEnabled ?? this.sosLiveLocationSharingEnabled,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
