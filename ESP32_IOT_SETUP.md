# SOZOTAP ESP32 Wi-Fi/GSM Device-to-Cloud Setup Guide

This document details the firmware architecture, build instructions, HTTPS TLS verification, and offline event queue for ESP32 hardware panic buttons.

---

## 1. Project Location & Toolchain
- **Firmware Path**: `firmware/esp32_sos_button/`
- **Toolchain**: ESP-IDF `v5.x` (or PlatformIO with C++17 support)
- **Target Hardware**: ESP32, ESP32-S3, or ESP32-C3 modules.

---

## 2. Hardware Interfaces & Pin Configuration
- **SOS Panic Button**: GPIO 0 (BOOT button on standard ESP32 boards)
  - Features: Active low, hardware debounced, **2-second hold required** to prevent accidental triggers.
- **Status LED**: GPIO 2 (Built-in blue LED)
  - Blinking / Solid states indicate `Connecting`, `Pairing`, `SosSent`, `Error`, or `LowBattery`.

---

## 3. HTTPS TLS Security Policy
ESP32 communication uses **strict HTTPS TLS server certificate verification** (`mbedtls`).
The device POSTs event JSON to `ingestDeviceEvent` Cloud Function REST endpoint:
```json
{
  "data": {
    "deviceId": "dev_esp32_001",
    "secretToken": "sample_secret_token",
    "eventId": "evt_1700000000",
    "eventType": "sos_pressed",
    "batteryLevel": 95
  }
}
```
> **SAFETY RULE**: The ESP32 device **never** holds direct Firestore credentials or Firebase Admin SDK keys.

---

## 4. Offline Event Queue & Retry Policy
If Wi-Fi connection drops, the firmware queues up to 10 events in a bounded FIFO queue (`OfflineQueue`). When connection is restored, pending emergency events are retried automatically.
