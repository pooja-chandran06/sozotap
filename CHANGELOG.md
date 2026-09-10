# SOZOTAP Changelog

All notable changes to the SOZOTAP emergency response mobile application and backend services will be documented in this file.

---

## [1.1.0] - Phase 9 IoT, BLE, NFC & Caregiver Access Foundation (2026-09-10)

### Added
- **NFC SmartTag Foundation (Phase 9.1)**: Added `nfc_manager: ^3.3.0`, `NfcTagRepository`, `NfcTagRepositoryImpl`, and `/devices/nfc` (`NfcManagementScreen`) supporting URI NDEF programming with zero PII and QR fallback notice.
- **BLE Wearable & Panic Button (Phase 9.2)**: Added `flutter_blue_plus: ^1.34.4`, `IoTDevice` and `DeviceEvent` models, `BleSosService` with custom GATT characteristic (`0000SOZO-0000-1000-8000-00805F9B34FB`) listener, pairing challenge flow, and `/devices` & `/devices/pair` screens.
- **ESP32 Wi-Fi/GSM Device-to-Cloud (Phase 9.3)**: Added Cloud Functions endpoints (`createDevicePairingSession`, `completeDevicePairing`, `revokeDevice`, `rotateDeviceCredential`, `ingestDeviceEvent`) and `firmware/esp32_sos_button/` ESP-IDF C++ baseline with 2s button hold debouncing, status LED, NTP time sync, HTTPS TLS verification, and offline FIFO queue.
- **Caregiver Access Foundation (Phase 9.4)**: Added `CaregiverRelationship` model, `CaregiverRepository`, Cloud Functions (`createCaregiverInvitation`, `acceptCaregiverInvitation`, `declineCaregiverInvitation`, `revokeCaregiverAccess`), `/caregivers` (`CaregiverListScreen`), and `/caregivers/invite` (`InviteCaregiverScreen`).
- **Security Rules & Testing (Phase 9.5)**: Updated `firestore.rules` and `firestore.indexes.json` for `/iot_devices`, `/device_events`, `/device_pairing_sessions`, `/caregiver_relationships`. Added unit and widget tests for NFC, BLE, IoT, and Caregiver modules. Created 6 technical documentation specs (`NFC_INTEGRATION.md`, `BLE_INTEGRATION.md`, `ESP32_IOT_SETUP.md`, `IOT_DEVICE_SECURITY.md`, `CAREGIVER_ACCESS.md`, `IOT_TESTING.md`).

---

## [1.0.0] - Phase 8 Release Readiness & Security Hardening (2026-09-10)
- Initial Phase 8 production security hardening, App Check, safe logging, CI/CD, and docs.
