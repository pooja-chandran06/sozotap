# SOZOTAP Settings & Privacy Architecture Guide

This document details the configuration options, theme architecture, locale structure, and granular privacy consent controls in SOZOTAP.

---

## 🎨 Theme & Appearance
SOZOTAP supports 3 theme modes managed via `SettingsRepository` and `ThemeModeNotifier`:
- `system`: Matches device operating system preference.
- `light`: Clean high-contrast light presentation.
- `dark`: Signature HSL Medical Slate Dark Theme (`#0F0F14`).

Theme selection is persisted locally using `SharedPreferences` (`app_theme_mode`).

---

## 🛡 Granular Privacy Consent Flags

Users retain full control over which medical fields are disclosed on the public emergency web card when paramedics scan their dynamic QR code.

| Flag Key | Description | Default |
| :--- | :--- | :---: |
| `emergencyAccessEnabled` | Master switch enabling public QR scan resolution | `true` |
| `shareNameInEmergency` | Expose legal full name | `true` |
| `sharePhotoInEmergency` | Expose profile photo for identity verification | `false` |
| `shareBloodGroupInEmergency` | Expose blood group (e.g. O Negative) | `true` |
| `shareAllergiesInEmergency` | Expose life-threatening allergies | `true` |
| `shareMedicalConditionsInEmergency` | Expose chronic medical conditions | `true` |
| `shareMedicationsInEmergency` | Expose daily medications | `true` |
| `shareImplantsInEmergency` | Expose pacemakers or metallic implants | `true` |
| `shareDoctorHospitalInEmergency` | Expose primary doctor & preferred hospital | `true` |
| `shareEmergencyContactsInEmergency` | Expose emergency contacts list | `true` |
| `shareHospitalDirectionsInEmergency` | Expose hospital address directions | `true` |
| `shareEmergencyNotesInEmergency` | Expose clinical emergency notes | `true` |
| `qrScanAlertEnabled` | Push alert when QR code is scanned | `true` |
| `sosLiveLocationSharingEnabled` | Attach live GPS coordinates to SOS alerts | `true` |

---

## 🔄 Authoritative Redaction Enforcement
Consent flags are saved to `users/{uid}/privacy_settings/settings` and mirrored to `medical_profiles/{uid}`. When `resolveEmergencyQr` executes in Firebase Cloud Functions v2, it checks these flags authoritatively:
- If `emergencyAccessEnabled === false`, the function throws `permission-denied` and returns a safe unavailable response.
- Any flag set to `false` replaces the respective DTO field with `"Restricted"` or `null`.
