# SOZOTAP Security & Data Privacy Policy

SOZOTAP implements strict zero-trust security practices to protect sensitive emergency and medical profile data.

---

## 🔒 Security Principles

### 1. No Secrets in Mobile Client
- No Firebase Admin SDK keys, Twilio auth tokens, FCM server keys, or webhook secrets reside in Flutter client code.
- All privileged dispatches and audit tracking are executed strictly within Firebase Cloud Functions v2.

### 2. PII & Medical Log Redaction
- All Cloud Functions logs strip sensitive information using `redactPhoneNumber()`, `redactFcmToken()`, `redactEmail()`, and `sanitizeLogObject()`.
- Exact GPS coordinates and medical details are redacted before writing to log sinks.

### 3. Idempotent Message Dispatch
- SHA-256 idempotency keys (`generateIdempotencyKey`) prevent duplicate notification sends during retry events or trigger re-executions.

### 4. Firestore Access Control
- Default deny policy on all collections.
- `device_tokens` and `notification_preferences` accessible only by the owner user (`request.auth.uid == userId`).
- `message_deliveries` client write access is completely blocked (`allow write: if false`). Writes permitted strictly via Admin SDK.

---

## 📋 Audit Logging
- Every notification dispatch creates a permanent audit record in `message_deliveries/{deliveryId}` containing status (`queued`, `sent`, `delivered`, `failed`, `skipped`), delivery channel, provider message ID, and failure code.
