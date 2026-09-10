# SOZOTAP IoT & Wearable Threat Model & Security Specification

This document details the security threat model, mitigation strategies, and attack prevention mechanisms for SOZOTAP NFC, BLE, ESP32, and Caregiver integrations.

---

## Threat Matrix & Mitigations

| Threat Vector | Potential Impact | SOZOTAP Mitigation Architecture |
|---------------|------------------|----------------------------------|
| **Lost / Stolen NFC Tag** | Physical tag found by unauthorized party | NFC tags store **only** an opaque URL token with zero PII. Revoking QR token in mobile app immediately invalidates the physical tag. |
| **BLE Spoofing / Unauthorized Pairing** | Rogue BLE device injecting fake alerts | Pairing requires explicit user selection and 6-digit challenge code validation. Auto-pairing is disabled. |
| **Stolen ESP32 Device** | Physical extraction of device chip | ESP32 stores only a short-lived, revocable `secretToken`. Device access can be revoked instantaneously via `/devices` screen or `revokeDevice` Cloud Function. |
| **Replayed SOS Event** | Event replay flooding backend with duplicate alerts | Ingestion endpoints enforce unique `idempotencyKey` tracking (`deviceId-eventId`). Replayed events return `{ status: "ignored" }`. |
| **Caregiver Overreach** | Caregivers attempting to edit medical profile or delete account | Caregiver grants use granular permission flags (`viewEmergencySummary`, `receiveSosAlerts`). Firestore rules prevent caregiver write access to private medical records. |
| **Sensor False Positives** | Accidental fall detection triggering panic alerts | Fall detection events trigger a 15-second mobile app confirmation prompt before dispatching emergency contacts. |
