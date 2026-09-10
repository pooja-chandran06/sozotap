# Firebase App Check Implementation Guide

This document details the configuration and architecture of Firebase App Check within SOZOTAP.

---

## Architecture & Integration
`AppCheckService` (`lib/core/services/app_check_service.dart`) handles attestation initialization during application startup in `main.dart`.

### Environment Configuration:
- **Debug Mode (`kDebugMode`)**: Activates `AndroidProvider.debug` and `AppleProvider.debug`. The debug secret token is printed in logcat for developer testing.
- **Release Mode**: Activates `AndroidProvider.playIntegrity` on Android and `AppleProvider.deviceCheck` / `appAttest` on iOS.

---

## Handling Public Paramedic Scans
The paramedic emergency QR viewer operates on a public web page (`https://vitanexus.web.app/scan?token=...`).
Because first responders viewing the emergency medical card do not possess the SOZOTAP mobile app or an App Check token, the backend Cloud Function `resolveEmergencyQr`:
1. Validates the high-entropy opaque token against hashed database records.
2. Enforces user master access toggles and privacy consent flags.
3. Does **not** require an App Check token for paramedic web viewer calls, ensuring emergency accessibility while retaining robust server-side authentication and rate limiting.

---

## Testing App Check locally
1. Launch app in debug mode on physical or virtual device.
2. Retrieve debug token from logcat: `FirebaseAppCheck: Enter this debug secret into the allow list in Firebase Console`.
3. Add the debug secret under Firebase Console -> App Check -> Apps -> Manage Debug Tokens.
