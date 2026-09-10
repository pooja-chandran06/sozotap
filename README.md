# SOZOTAP / VITANEXUS

> **"One Tap Can Save a Life."**

SOZOTAP is a secure emergency medical information system and SOS alert mobile application built with Flutter, Firebase Authentication, Cloud Firestore, Firebase Storage, Firebase Cloud Messaging (FCM), and Firebase Cloud Functions v2.

---

## Key Features
- **3-Second SOS Trigger**: Fast emergency dispatch with audio countdown, live GPS location capture, and quick cancellation.
- **Paramedic Public Medical Viewer**: Secure, high-entropy dynamic QR code token scanning rendering a mobile-friendly web view (`/scan?token=...`) for first responders without requiring app installation.
- **Granular Privacy Controls**: 14 user consent flags allowing users to individually control public emergency access to name, photo, blood group, allergies, conditions, medications, implants, doctor info, emergency contacts, hospital directions, and notes.
- **Dual-Channel Notification Engine**: High-priority FCM push notifications backed by automatic SMS fallback via Twilio when FCM token delivery fails or expires.
- **Hive Offline Architecture**: Full offline capability with user-isolated Hive local storage (`user_<uid>_*`), connectivity listener, and top offline banner UI.
- **Firebase App Check & Hardened Security**: Attestation via Debug provider in development and Play Integrity on Android release. Strict Firestore and Storage rules with zero hardcoded secrets.

---

## Technology Stack
- **Frontend Framework**: Flutter `3.22.x` (Dart 3)
- **State Management**: Flutter Riverpod `^2.5.1`
- **Navigation & Routing**: GoRouter `^13.2.0`
- **Backend Infrastructure**: Firebase Cloud Functions v2 (TypeScript / Node 18)
- **Database & Storage**: Cloud Firestore, Firebase Storage, Hive Local Storage
- **Authentication**: Firebase Authentication (Email/Password, Google Sign-In)
- **Push & Messaging**: Firebase Cloud Messaging (FCM), Twilio SMS API fallback
- **App Attestation**: Firebase App Check (Play Integrity / DeviceCheck / Debug)

---

## Directory Structure
```
sozotap/
├── .github/
│   ├── workflows/          # GitHub Actions CI/CD workflows for Flutter & Cloud Functions
│   └── dependabot.yml      # Dependabot update configuration
├── android/                # Native Android application configuration & manifests
├── backend/
│   └── public/index.html   # Public Paramedic Emergency Web Card HTML/JS viewer
├── functions/              # Firebase Cloud Functions v2 TypeScript source & tests
│   ├── src/                # SOS dispatch, QR resolution, FCM, SMS fallback, account deletion
│   └── test/               # Cloud Functions Jest unit tests
├── lib/
│   ├── authentication/     # Auth repository, screens, Riverpod providers
│   ├── core/               # SafeLogger, AppException, ErrorMapper, AppCheckService, Hive cache
│   ├── dashboard/          # Home dashboard, quick SOS button, navigation shell
│   ├── emergency_contacts/ # Emergency contacts management repository & screens
│   ├── medical_profile/    # Medical profile management repository & UI
│   ├── notifications/      # FCM handler, local notifications, inbox history screen
│   ├── qr/                 # Dynamic QR token generation, scanner, revocation
│   ├── settings/           # Settings UI, 14 consent privacy flags, theme provider
│   └── sos/                # 3-second SOS countdown engine, active emergency alert state
├── firestore.rules         # Hardened Firestore security rules
├── storage.rules           # Hardened Firebase Storage security rules
├── firestore.indexes.json  # Production composite database indexes
├── firebase.json           # Firebase CLI & Emulator Suite configuration
└── test/                   # Flutter unit and widget tests
```

---

## Getting Started

### 1. Requirements
- Flutter SDK `3.22.x`
- Java JDK 17
- Node.js 18 (for Firebase Cloud Functions)
- Firebase CLI (`npm install -g firebase-tools`)

### 2. Installation
```bash
# Clone repository
git clone https://github.com/vitanexus/sozotap.git
cd sozotap

# Install Flutter dependencies
flutter pub get

# Install Cloud Functions dependencies
cd functions && npm install && cd ..
```

### 3. Running Local Emulators
```bash
firebase emulators:start
```

### 4. Running the Flutter Application
```bash
flutter run
```

---

## Documentation Suite
- [Architecture & Design](file:///d:/VITANEXUS/sozotap/ARCHITECTURE.md)
- [Firebase Setup Guide](file:///d:/VITANEXUS/sozotap/FIREBASE_SETUP.md)
- [Cloud Functions Setup](file:///d:/VITANEXUS/sozotap/FIREBASE_FUNCTIONS_SETUP.md)
- [Security Guidelines](file:///d:/VITANEXUS/sozotap/SECURITY.md)
- [App Check Setup](file:///d:/VITANEXUS/sozotap/APP_CHECK.md)
- [Testing Guide](file:///d:/VITANEXUS/sozotap/TESTING.md)
- [Firebase Emulator Suite](file:///d:/VITANEXUS/sozotap/EMULATOR_SETUP.md)
- [Privacy & Data Handling](file:///d:/VITANEXUS/sozotap/PRIVACY_AND_DATA_HANDLING.md)
- [API Documentation](file:///d:/VITANEXUS/sozotap/API_DOCUMENTATION.md)
- [Android Release Guide](file:///d:/VITANEXUS/sozotap/DEPLOYMENT_ANDROID.md)
- [Release Checklist](file:///d:/VITANEXUS/sozotap/RELEASE_CHECKLIST.md)
- [Contributing](file:///d:/VITANEXUS/sozotap/CONTRIBUTING.md)
- [Changelog](file:///d:/VITANEXUS/sozotap/CHANGELOG.md)

---

## License & Copyright
Copyright © 2026 VITANEXUS / SOZOTAP Team. All rights reserved.
