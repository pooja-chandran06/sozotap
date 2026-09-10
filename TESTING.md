# SOZOTAP Testing & Emulator Guide

This document explains how to execute unit tests, local emulator suite testing, and physical device verification.

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

### Flutter Client Unit & Widget Tests
```bash
flutter test
```
**Tests Covered**:
- `DeviceToken` map serialization
- `NotificationItem` inbox model & privacy check
- `NotificationPreference` default states and `copyWith`
- `AppRouter` route definitions

---

## 🎛 2. Firebase Emulator Suite Setup

To test Firestore triggers and callable functions locally without impacting production data:

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
```

---

## 📱 3. Real Device FCM Verification Checklist

To perform full end-to-end FCM verification:

- [ ] Deploy Cloud Functions using `firebase deploy --only functions`.
- [ ] Install app build on physical Android or iOS device (FCM push notifications do not work on standard iOS Simulators).
- [ ] Sign in to SOZOTAP and grant notification permissions.
- [ ] Verify `users/{uid}/device_tokens/{tokenId}` record is created in Firestore.
- [ ] Add emergency contact with recipient user ID linked to your device.
- [ ] Trigger an SOS alert on sender device.
- [ ] Verify instant push notification arrives on recipient device with sound and vibration.
- [ ] Tap notification and verify app opens directly to `/sos-alert/{alertId}`.
- [ ] Mark alert as resolved on sender device and verify resolution push arrives.

---

> **Note**: Full end-to-end FCM and SMS network delivery requires physical hardware and registered credentials. Automated unit tests validate logic, privacy rules, and error handling safely.
