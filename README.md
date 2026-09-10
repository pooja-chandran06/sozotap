# SOZOTAP / VITANEXUS

> **One Tap Can Save a Life.**
> Secure Emergency Medical Information & SOS Dispatch System.

---

## 📌 Project Overview
SOZOTAP is a cross-platform emergency response application designed for instant SOS alert triggering, dynamic QR code medical profile scanning for first responders, multi-channel backend notification dispatch (FCM push & SMS fallback), user privacy consent controls, offline cache synchronization, and protected account controls.

---

## 🛠 Tech Stack
- **Frontend App**: Flutter 3 (Material 3 Theme Switcher), Dart, Riverpod 2.5, GoRouter, Hive 2.2, Connectivity Plus, Package Info Plus
- **Backend Infrastructure**: Firebase Functions v2 (TypeScript), Cloud Firestore, Firebase Auth, FCM, Firebase Storage
- **Local Storage & Utilities**: Hive Flutter, SharedPreferences, Geolocator, MobileScanner, QR Flutter, Permission Handler

---

## 📂 Project Architecture
```
sozotap/
├── android/                 # Android app build configurations
├── functions/               # Firebase Cloud Functions v2 (TypeScript)
│   ├── src/
│   │   ├── config.ts        # Secrets and constants
│   │   ├── types.ts         # TypeScript data interfaces
│   │   ├── services/        # FCM, SMS & Delivery Services
│   │   ├── utils/           # Redaction, Logger & Idempotency
│   │   └── index.ts         # Firestore triggers, QR & deleteUserAccount callable endpoints
│   └── test/                # Cloud Functions unit tests
├── lib/
│   ├── authentication/      # Auth screens, OTP & Firebase Auth state
│   ├── core/                # Offline Hive cache, connectivity & security utilities
│   ├── emergency_contacts/  # Contact management & SMS opt-in consent
│   ├── medical_profile/     # Medical data models & consent settings
│   ├── notifications/       # FCM client, Inbox UI & Notification Settings
│   ├── qr/                  # Dynamic QR lifecycle, scanner & web card viewer
│   ├── routes/              # GoRouter router definitions
│   ├── settings/            # Theme, Privacy Settings, About & Account Controls
│   └── sos/                 # SOS countdown, active alert screen & detail view
├── firestore.rules          # Security rules enforcing strict access control
├── firestore.indexes.json   # Firestore query index specifications
├── storage.rules            # Firebase Storage security rules
└── firebase.json            # Firebase configuration
```

---

## 🚀 Getting Started

### 1. Prerequisites
- Flutter SDK `>=3.0.0`
- Node.js `v18+`
- Firebase CLI (`npm install -g firebase-tools`)

### 2. Mobile App Setup
```bash
flutter pub get
flutter run
```

### 3. Cloud Functions Build & Local Emulator
```bash
cd functions
npm install
npm run build
npm run serve
```

---

## 📚 Documentation
- [FIREBASE_FUNCTIONS_SETUP.md](FIREBASE_FUNCTIONS_SETUP.md) — Backend Functions installation & deployment guide.
- [FCM_SETUP.md](FCM_SETUP.md) — Firebase Cloud Messaging configuration & Android/iOS setup.
- [SMS_PROVIDER_SETUP.md](SMS_PROVIDER_SETUP.md) — Twilio SMS secrets setup, regional laws & consent policy.
- [SETTINGS_AND_PRIVACY.md](SETTINGS_AND_PRIVACY.md) — Theme, privacy consent flags & redaction policy.
- [OFFLINE_SUPPORT.md](OFFLINE_SUPPORT.md) — Hive offline cache, namespacing & connectivity monitoring.
- [ACCOUNT_DELETION.md](ACCOUNT_DELETION.md) — Protected Cloud Function account deletion protocol.
- [SECURITY.md](SECURITY.md) — Security rules, data policy & HIPAA/GDPR privacy guidelines.
- [TESTING.md](TESTING.md) — Unit testing, Firebase Emulator suite instructions & device testing checklist.

---

## ⚖️ Legal & Disclaimer
SOZOTAP is an emergency communication app between users and designated emergency contacts. SOZOTAP **does not** dispatch government emergency services (such as 911 or 112) unless a certified integration exists in your jurisdiction.
