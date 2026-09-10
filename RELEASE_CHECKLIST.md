# SOZOTAP Production Release Checklist

Before tagging a version or deploying SOZOTAP to production, complete all verification steps in this checklist.

---

## 1. Codebase & Static Analysis
- [ ] `flutter analyze` passes with 0 warnings or errors.
- [ ] `functions/npm run lint` passes with 0 warnings or errors.
- [ ] No hardcoded API keys, secrets, test tokens, or private URLs in client or backend code.
- [ ] `pubspec.yaml` version and build number updated appropriately.

---

## 2. Automated Tests & Build Verification
- [ ] `flutter test` passes all unit and widget tests.
- [ ] `cd functions && npm test` passes all Cloud Functions unit tests.
- [ ] `flutter build appbundle --release` builds successfully.

---

## 3. Firebase Security & Configuration
- [ ] `firestore.rules` deployed with default deny, owner-only write isolation, and immutable audit fields.
- [ ] `storage.rules` deployed with 5MB max size restriction and `image/*` MIME type validation.
- [ ] Firestore indexes (`firestore.indexes.json`) deployed and active.
- [ ] Firebase App Check registered with Play Integrity / DeviceCheck.
- [ ] Twilio / SMS fallback API secrets configured in Firebase Secret Manager (`TWILIO_ACCOUNT_SID`, `TWILIO_AUTH_TOKEN`, `TWILIO_PHONE_NUMBER`).

---

## 4. Privacy & Consent Controls
- [ ] 14 user privacy consent flags tested (disabling flags excludes medical data from public QR web card view).
- [ ] Master Emergency Access toggle tested (disabling toggle immediately returns 403 / unavailable on public paramedic viewer).
- [ ] Dynamic QR token lifecycle tested (revoke, regenerate, 30-day token rotation).
- [ ] Account deletion (`deleteUserAccount` Cloud Function) verified to delete Firestore data, Storage files, and Auth user record.

---

## 5. Emergency Engine & Notifications
- [ ] SOS 3-second countdown and cancellation tested.
- [ ] FCM push notifications delivered to priority contacts upon SOS trigger.
- [ ] SMS fallback executed when FCM token is invalid or push delivery fails.
- [ ] Notification history recorded in recipient inbox with correct status (`delivered`, `read`).
- [ ] Offline caching verified (app functions seamlessly when network connection is disconnected).

---

## 6. Play Store & Regulatory Compliance
- [ ] Android Manifest permissions audited.
- [ ] Play Console Data Safety form completed accurately.
- [ ] Terms of Service and Privacy Policy URLs accessible.
