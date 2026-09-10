# SOZOTAP Testing & Emulator Guide

This document explains how to execute unit tests, local emulator suite testing, and physical device verification for SOZOTAP Phase 7.

---

## 🧪 1. Unit Tests

### Cloud Functions Unit Tests (TypeScript / Jest)
```bash
cd functions
npm test
```
**Tests Covered**:
- SHA-256 idempotency key generation & uniqueness
- Log redaction of phone numbers, FCM tokens, emails, and medical PII
- E.164 phone format validation
- `DisabledSmsProvider` non-crashing fallback behavior
- Notification payload privacy compliance
- Privacy consent flag redactions (`Restricted` responses)

### Flutter Client Unit & Widget Tests
```bash
flutter test
```
**Tests Covered**:
- `DeviceToken` map serialization
- `NotificationItem` inbox model & privacy check
- `NotificationPreference` default states and `copyWith`
- `PrivacySettingsModel` recommended preset and `copyWith`
- `HiveCacheService` secret token stripping and namespace isolation
- Connectivity state mapping and offline indicator
- `AppRouter` route definitions

---

## 🎛 2. Firebase Emulator Suite Setup

To test Firestore triggers, Cloud Functions, and Storage rules locally:

1. **Start Emulator Suite**:
```bash
firebase emulators:start
```

2. **Access Emulator UI**:
Open `http://localhost:4000` in your web browser.

3. **Connect Flutter App to Emulator**:
```dart
FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
FirebaseFunctions.instance.useFunctionsEmulator('localhost', 5001);
```

---

## 📱 3. Manual Verification Checklist for Phase 7

- [ ] Open Settings (`/settings`) and switch Theme between System, Light, and Dark. Verify app appearance updates.
- [ ] Open Privacy & Emergency Sharing (`/settings/privacy`) and toggle sharing flags. Tap **Reset to Recommended** and verify defaults restore.
- [ ] Scan user QR code with `emergencyAccessEnabled = false` and verify public viewer displays unavailable state.
- [ ] Disconnect internet connection (Airplane Mode) and verify top `OfflineBannerWidget` appears with **Last Synced** timestamp.
- [ ] Sign out of Account and verify local Hive cache boxes (`user_<uid>_*`) are purged.
- [ ] Open Account Controls (`/account`), select Delete Account, type **DELETE** confirmation phrase, and verify account cleanup.
