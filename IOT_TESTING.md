# SOZOTAP IoT & Hardware Testing Guide

This document describes how to execute automated unit, widget, and integration tests for NFC, BLE, ESP32, and Caregiver modules.

---

## 1. Unit & Widget Test Execution
```bash
# Run all Flutter unit and widget tests
flutter test

# Run NFC payload test
flutter test test/unit/nfc_payload_test.dart

# Run IoT device model test
flutter test test/unit/iot_device_model_test.dart

# Run BLE event parser test
flutter test test/unit/ble_event_parser_test.dart

# Run Caregiver relationship test
flutter test test/unit/caregiver_relationship_test.dart
```

---

## 2. Cloud Functions IoT & Caregiver Tests
```bash
cd functions

# Run Cloud Functions Jest unit tests
npm test
```

---

## 3. Hardware Validation Checklist (Pending Real Hardware)
- [ ] Program NTAG215 chip via `/devices/nfc` and scan with secondary smartphone.
- [ ] Pair physical ESP32 BLE device via `/devices/pair` and press hardware button.
- [ ] Connect ESP32 Wi-Fi module to test router and verify `ingestDeviceEvent` HTTPS response.
