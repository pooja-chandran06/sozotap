# SOZOTAP Privacy & Data Handling Specification

SOZOTAP is engineered around patient sovereignty and explicit medical data consent. This document details data handling practices, consent flag definitions, and account deletion flows.

---

## 1. 14 Granular User Privacy Consent Flags

Users possess granular control over every data field exposed on the public paramedic emergency web viewer:

| Consent Flag | Description | Recommended Default |
|--------------|-------------|---------------------|
| `emergencyAccessEnabled` | Master toggle to enable/disable public QR response | `true` |
| `shareNameInEmergency` | Share full legal name | `true` |
| `sharePhotoInEmergency` | Share profile photo for identity verification | `true` |
| `shareBloodGroupInEmergency` | Share blood group for transfusion safety | `true` |
| `shareAllergiesInEmergency` | Share critical food/drug allergies | `true` |
| `shareMedicalConditionsInEmergency` | Share chronic conditions (Diabetes, Epilepsy) | `true` |
| `shareMedicationsInEmergency` | Share active medications to prevent interactions | `true` |
| `shareImplantsInEmergency` | Share implants (Pacemaker, Metal Pins) | `true` |
| `shareDoctorHospitalInEmergency` | Share doctor & preferred hospital name | `false` |
| `shareEmergencyContactsInEmergency` | Share emergency contacts list | `true` |
| `shareHospitalDirectionsInEmergency` | Share hospital address directions | `false` |
| `shareEmergencyNotesInEmergency` | Share custom emergency instructions | `true` |
| `qrScanAlertEnabled` | Push notification alert when QR is scanned | `true` |
| `sosLiveLocationSharingEnabled` | Share live GPS coordinates during SOS alert | `true` |

---

## 2. Right to Erasure / Account Deletion

Under GDPR / HIPAA compliance policies:
1. Users can trigger account deletion in `Account & Security Controls`.
2. Execution triggers `deleteUserAccount` Cloud Function v2:
   - Purges user profile and medical documents from Firestore (`/users/{uid}`, `/medical_profiles/{uid}`).
   - Purges emergency contacts and QR tokens (`/emergency_contacts`, `/emergency_qr_tokens`).
   - Purges uploaded profile pictures from Firebase Storage (`users/{uid}/*`).
   - Permanently deletes Firebase Authentication user record.
3. Flutter client clears local Hive boxes (`clearUserCache(uid)`).
