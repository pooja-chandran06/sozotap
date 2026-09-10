# SOZOTAP Security & Data Privacy Policy

SOZOTAP implements strict zero-trust security practices to protect sensitive emergency and medical profile data.

---

## 🔒 Security Principles

### 1. No Secrets in Mobile Client or Local Cache
- No Firebase Admin SDK keys, Twilio auth tokens, FCM server keys, or webhook secrets reside in Flutter client code.
- Passwords, raw secret QR tokens, and raw Admin keys are NEVER saved in offline Hive cache or local storage.
- User offline Hive boxes are key-namespaced by User ID (`user_<uid>_profile`) and purged on logout.

### 2. PII & Medical Log Redaction
- All Cloud Functions logs strip sensitive information using `redactPhoneNumber()`, `redactFcmToken()`, `redactEmail()`, and `sanitizeLogObject()`.
- Exact GPS coordinates and medical details are redacted before writing to log sinks.

### 3. Authoritative Consent Redaction
- Paramedic QR resolution (`resolveEmergencyQr`) reads user-configured privacy consent flags (`shareBloodGroupInEmergency`, `shareAllergiesInEmergency`, etc.) as authoritative redaction controls.
- Disabling `emergencyAccessEnabled` blocks public QR resolution completely.

### 4. Protected Cloud Function Account Deletion
- Destructive account deletion (`deleteUserAccount`) is executed via an authenticated Firebase Cloud Function that revokes QR tokens, deletes Firestore documents, removes Storage assets, and deletes the Auth user account.

---

## 📋 Firestore & Storage Access Rules
- Default deny policy on all collections and storage buckets.
- `device_tokens`, `notification_preferences`, `privacy_settings`, and `medical_profiles` accessible only by the owner user (`request.auth.uid == userId`).
- `message_deliveries` client write access is completely blocked (`allow write: if false`).
