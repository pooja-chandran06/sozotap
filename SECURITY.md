# SOZOTAP Security & Data Protection Policy

Security and patient data confidentiality are the highest priorities of SOZOTAP. This document summarizes key security policies and mechanisms.

---

## 1. Zero Secrets Policy
- Client application builds **must never** contain hardcoded API keys, database credentials, server secrets, or private tokens.
- FCM Server Keys, Twilio Auth Tokens, and Service Account Keys are strictly isolated within Firebase Secret Manager and accessed exclusively by Cloud Functions v2 Admin SDK.

---

## 2. PII & Medical Data Redaction
- Console logging across Flutter app is routed through `SafeLogger`.
- `SafeLogger` automatically redacts emails (`j***e@domain`), phone numbers (`+14****2671`), bearer/auth tokens, GPS coordinates, and medical record values prior to print.
- Raw stack traces and raw database errors are intercepted by `ErrorMapper` to return non-revealing, user-safe error messages.

---

## 3. Storage & Database Security Rules
- **Firestore Security Rules**: Default deny all access. User data is partitioned by `request.auth.uid`. Fields like `alert_sent`, `token_hash`, and backend timestamps cannot be modified by client SDKs.
- **Storage Security Rules**: Default deny all access. User file uploads are limited to `users/{uid}/profile/*`, enforcing a max size of `< 5MB` and MIME type `image/.*`.

---

## 4. App Attestation & Tamper Protection
- Firebase App Check is enabled via `AppCheckService`.
- Release builds enforce Play Integrity attestation on Android devices.
- Unauthenticated or tampered requests are rejected at the Firebase edge before reaching Firestore or Cloud Functions.

---

## 5. Vulnerability Reporting
To report security vulnerabilities or data exposure concerns, please email: `security@vitanexus.app`.
