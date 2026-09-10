# SOZOTAP Changelog

All notable changes to the SOZOTAP emergency response mobile application and backend services will be documented in this file.

---

## [1.0.0] - Phase 8 Release Readiness & Security Hardening (2026-09-10)

### Added
- **Firebase App Check Integration**: Added `firebase_app_check` dependency and `AppCheckService` with Play Integrity release attestation and Debug provider support.
- **Centralized Safe Logger**: Implemented `SafeLogger` with automatic redaction of emails, phone numbers, tokens, GPS coordinates, and medical record keys.
- **Structured Error Handling**: Added `AppException` typed exception hierarchy and `ErrorMapper` utility for non-revealing error transformations.
- **Unit & Widget Test Suites**: Added `safe_logger_test.dart`, `error_mapper_test.dart`, `app_check_service_test.dart`, `settings_screen_widget_test.dart`, and `privacy_settings_screen_widget_test.dart`.
- **CI/CD Pipeline**: Configured GitHub Actions workflows (`flutter_ci.yml`, `functions_ci.yml`) and Dependabot (`dependabot.yml`).
- **Android Release Infrastructure**: Created `key.properties.example`, `DEPLOYMENT_ANDROID.md`, and `RELEASE_CHECKLIST.md`.
- **Complete Documentation Suite**: Created/updated 13 Markdown technical specifications.

### Security
- **Hardened Firestore Rules**: Added `signedIn()`, `isOwner()`, `hasOnlyAllowedKeys()`, default deny all, immutable audit fields protection.
- **Hardened Storage Rules**: Enforced 5MB file size limit, `image/*` MIME type restriction, and owner-only path isolation.
- **Firebase Emulator Suite**: Added Auth (9099), Firestore (8080), Functions (5001), Storage (9199), and UI Dashboard (4000) configuration to `firebase.json`.
