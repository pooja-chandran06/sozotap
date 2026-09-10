# SOZOTAP Project Documentation Summary & Repository Audit Report

> **Project Name**: SOZOTAP  
> **Tagline**: “One Tap Can Save a Life.”  
> **Project Category**: Secure Emergency Medical Information and SOS Alert Mobile Application  
> **Primary Platform**: Android (Built with Flutter 3 & Firebase)  
> **Documentation File**: `SOZOTAP_Mobile_Application_Project_Documentation.docx`

---

## 📌 Executive Summary
SOZOTAP is an emergency health information and SOS notification support application designed to provide immediate access to vital medical details (blood group, critical allergies, chronic conditions, daily medications, emergency contacts) during crises when patients may be incapacitated. 

The application strictly separates public emergency QR scanning from private database records through opaque SHA-256 hashed tokens (`https://vitanexus.web.app/qr/<token>`) and authoritative user privacy consent flags.

> **Disclaimer**: SOZOTAP is an emergency information-support system. It does not replace doctors, hospitals, ambulances, official government emergency services (911/112), or professional medical assessment.

---

## 🛠 Feature & Implementation Status Audit Table

| Requirement ID | Module / Feature Title | Description & Behavior | Implementation Status | Repository Evidence Path |
| :--- | :--- | :--- | :---: | :--- |
| **FR-AUTH-001** | User Authentication | Email/Password login, signup, OTP & persistent session | **Implemented** | `lib/authentication/presentation/screens/login_screen.dart` |
| **FR-ONB-001** | Interactive Onboarding | Multi-step feature walkthrough carousel with state persistence | **Implemented** | `lib/presentation/onboarding/onboarding_screen.dart` |
| **FR-DASH-001** | Emergency Dashboard | Home screen hub featuring quick SOS, QR card & contact shortcuts | **Implemented** | `lib/presentation/dashboard/home_screen.dart` |
| **FR-MED-001** | Medical Profile Management | CRUD for blood type, allergies, conditions, medications, physician | **Implemented** | `lib/medical_profile/presentation/screens/medical_profile_edit_screen.dart` |
| **FR-CON-001** | Emergency Contacts & Consent | Contact priority sorting, phone normalization & SMS opt-in consent | **Implemented** | `lib/emergency_contacts/presentation/screens/add_edit_contact_screen.dart` |
| **FR-SOS-001** | 3-Second SOS Trigger Engine | Press & hold button with countdown, audio/haptics & GPS capture | **Implemented** | `lib/sos/presentation/screens/sos_countdown_screen.dart` |
| **FR-QR-001** | Dynamic QR Token Lifecycle | Callable Cloud Functions v2 generator of SHA-256 hashed QR tokens | **Implemented** | `functions/src/index.ts` (`createEmergencyQr`) |
| **FR-SCAN-001** | Scanner & Paramedic Web Viewer | Mobile camera QR scanner & public web card viewer | **Implemented** | `lib/qr/presentation/screens/qr_scanner_screen.dart` |
| **FR-NOT-001** | Cloud Functions FCM & SMS | Firestore v2 trigger broadcasting FCM push alerts & fallback SMS | **Implemented** | `functions/src/index.ts` (`onEmergencyAlertCreated`) |
| **FR-SET-001** | App Settings & Theme Mode | System, Light, and Dark theme toggling via SharedPreferences | **Implemented** | `lib/settings/presentation/screens/settings_screen.dart` |
| **FR-PRI-001** | Privacy Consent Switches | 14 granular switches controlling public QR medical field disclosure | **Implemented** | `lib/settings/presentation/screens/privacy_settings_screen.dart` |
| **FR-OFF-001** | Hive Offline Cache & Banner | Namespaced local cache (`user_<uid>_*`) with visual status bar | **Implemented** | `lib/core/offline/hive_cache_service.dart` |
| **FR-ACC-001** | Protected Account Deletion | Re-auth & Cloud Function cleanup requiring 'DELETE' text | **Implemented** | `lib/settings/presentation/widgets/delete_account_dialog.dart` |
| **FR-IOT-001** | NFC, BLE & ESP32 Integration | Hardware panic button, wearable BLE triggers & NFC SmartTags | **Planned / Future Scope** | Architecture Specs & Documentation |

---

## 🔒 Security & Data Privacy Policy Summary

1. **Zero Client Secrets**: No Firebase Admin SDK keys, Twilio auth tokens, FCM server keys, or API secrets reside in Flutter client code.
2. **Log Redaction**: Cloud Functions logs automatically strip phone numbers (`+14****71`), FCM tokens, emails, and medical PII (`sanitizeLogObject`).
3. **Authoritative Redaction**: The paramedic QR resolution Cloud Function (`resolveEmergencyQr`) reads user-configured privacy consent flags as authoritative controls. If `emergencyAccessEnabled` is false, it returns a safe unavailable response.
4. **Idempotent Dispatch**: SHA-256 idempotency keys (`generateIdempotencyKey`) prevent duplicate notification sends.
5. **Cache Isolation**: User offline Hive boxes are key-namespaced by User ID (`user_<uid>_profile`) and purged on logout (`clearUserCache`).

---

## 📊 Final Evidence and Gaps Matrix

| Component | Repository File Path | Implementation Status | Next Recommended Action |
| :--- | :--- | :---: | :--- |
| **Flutter App Core** | `lib/main.dart` | Implemented | Configure Android release key properties for Play Store |
| **Theme & Settings** | `lib/settings/presentation/screens/settings_screen.dart` | Implemented | Add multi-language translation strings (`arb` files) |
| **Privacy Consent** | `lib/settings/presentation/screens/privacy_settings_screen.dart` | Implemented | Periodic security audit of Firestore consent mirror |
| **Offline Sync** | `lib/core/offline/hive_cache_service.dart` | Implemented | Expand Hive adapters for offline photo caching |
| **Cloud Functions** | `functions/src/index.ts` | Implemented | Deploy secrets via `firebase functions:secrets:set` |
| **Security Rules** | `firestore.rules` & `storage.rules` | Implemented | Deploy rules via `firebase deploy --only firestore,storage` |
| **Hardware / IoT** | Future Scope | Planned | Develop ESP32 Wi-Fi/GSM hardware prototype |

---

## 🎓 Project Viva Summary (1-Page Fast Reference)

- **Problem Statement**: During medical crises, patients may be unconscious or unable to communicate critical medical history (blood group, severe allergies, medications, emergency contacts). Physical paper cards can be lost or expose private data permanently.
- **Proposed Solution**: SOZOTAP combines instant 3-second SOS alert triggering with dynamic zero-trust QR codes. Scanned QR codes point to opaque tokens resolved by a protected Cloud Function that applies the user's granular privacy consent settings before displaying a redacted public web card to paramedics.
- **Technologies Used**: Flutter 3 (Material 3 Theme Switcher), Firebase Auth, Cloud Firestore, Firebase Cloud Messaging (FCM), Firebase Cloud Functions v2 (TypeScript), Firebase Storage, Hive 2.2, Riverpod 2.5, GoRouter 13.
- **Key Security Features**: Log redaction, zero client secrets, SHA-256 idempotency keys, namespaced Hive cache isolation (`user_<uid>_*`), and protected Cloud Function account deletion requiring explicit `DELETE` confirmation.
- **Future Expansion**: NFC SmartTags, BLE wearable SOS buttons, ESP32 panic devices, and caregiver portals.
