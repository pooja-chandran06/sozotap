# SOZOTAP Technical Architecture

This document describes the high-level architecture, design patterns, data flow, and security isolation mechanisms implemented in SOZOTAP.

---

## Architectural Pattern: Clean Architecture & Feature-First MVVM

SOZOTAP follows **Clean Architecture** principles structured by feature directories:

```
lib/<feature_name>/
├── data/
│   ├── datasources/        # Remote (Firestore/Functions) and Local (Hive) data sources
│   ├── models/             # Data Transfer Objects (DTOs) with JSON serialization
│   └── repositories/       # Concrete implementation of domain interfaces
├── domain/
│   ├── models/             # Domain entities and business logic validation
│   └── repositories/       # Abstract repository interfaces
└── presentation/
    ├── controllers/        # StateNotifier / Riverpod controllers
    ├── providers/          # Riverpod dependency injection definitions
    ├── screens/            # Full page UI views
    └── widgets/            # Feature-specific reusable UI components
```

---

## Data Layer & Offline Synchronization Architecture

1. **Hive Storage Isolation**:
   - Each authenticated user gets a separate Hive box prefixed with `user_<uid>_*` (e.g. `user_abc123_medical_profile`, `user_abc123_contacts`).
   - On sign-out, `clearUserCache(uid)` purges the active user's local cache without leaking data to subsequent account sign-ins.
2. **Offline-First Synchronization**:
   - Read requests first attempt local Hive retrieval, falling back to Firestore when online.
   - Updates write directly to Hive first, followed by asynchronous Firestore sync.
   - `connectivity_plus` and `internet_connection_checker_plus` feed into `connectivityStreamProvider` to render an unobtrusive offline warning banner (`OfflineBannerWidget`).

---

## Emergency Dispatch & Notification Flow

```
[Flutter App: SOS Button] 
       │
       ▼ (3s Countdown)
[Firestore write: /emergency_alerts/{alertId}]
       │
       ▼ (Firestore onCreate Trigger)
[Cloud Function v2: sendEmergencyAlert]
       │
       ├─────────────────────────────────┐
       ▼                                 ▼
[FCM High Priority Push]         [Twilio SMS Fallback Engine]
       │                                 │
       ▼                                 ▼
[Emergency Contact Device]       [SMS Phone Number]
```

---

## Security & Privacy Architecture
1. **Dynamic QR Token Security**:
   - Dynamic QR codes encode opaque high-entropy tokens: `https://vitanexus.web.app/scan?token=sozo_live_...`.
   - The token contains no PII or medical data directly.
   - Scanning triggers `resolveEmergencyQr` Cloud Function v2 which hashes the token, matches `emergency_qr_tokens`, verifies master access flags and user-defined consent settings, and returns filtered medical fields.
2. **Centralized Logging & Redaction**:
   - `SafeLogger` automatically redacts email addresses, phone numbers, auth tokens, coordinates, and medical record keys prior to console output.
3. **App Attestation**:
   - `AppCheckService` initializes Play Integrity provider on Android release devices, preventing unauthorized API invocations by tampered software.
