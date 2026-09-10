# SOZOTAP BLE Wearable & Panic Button Integration

This document outlines the Bluetooth Low Energy (BLE) architecture, pairing flow, GATT service definitions, and deduplication logic for SOZOTAP emergency hardware.

---

## 1. GATT Service & Characteristic Specifications
SOZOTAP BLE wearables advertise a custom primary service UUID:

- **Service UUID**: `0000SOZO-0000-1000-8000-00805F9B34FB`
- **SOS Notification Characteristic UUID**: `0000SOZO-0001-1000-8000-00805F9B34FB`
  - Properties: `NOTIFY`, `INDICATE`
  - Payload Format: `SOS:<eventId>:<batteryLevel>` (e.g. `SOS:evt_1700000000:92`)

---

## 2. Discovery & Explicit Pairing Flow
1. **Scanning**: User navigates to `/devices/pair` (`BlePairingScreen`). App scans for nearby devices using `flutter_blue_plus`.
2. **Explicit Selection**: Auto-pairing is strictly prohibited. User selects the target device explicitly.
3. **Challenge Validation**: Mobile app connects, discovers services, and subscribes to the SOS characteristic notification stream.
4. **Backend Registration**: `BleSosService` creates `IoTDevice` model and registers it under `/iot_devices/{deviceId}` in Firestore.

---

## 3. Duplicate Prevention & Event Deduplication
Incoming GATT notifications are processed through `idempotencyKey` tracking (`deviceId-eventId`).
If a hardware button sends duplicate packets due to retry or signal bounce, duplicate event IDs are caught and ignored cleanly by `IoTDeviceRepositoryImpl`.
