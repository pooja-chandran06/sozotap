# Firebase Local Emulator Suite Guide

This document describes how to start, connect to, and develop using the Firebase Local Emulator Suite for SOZOTAP.

---

## 1. Emulator Ports & Configuration
Firebase Local Emulator ports are defined in `firebase.json`:
- **Auth Emulator**: Port `9099`
- **Firestore Emulator**: Port `8080`
- **Cloud Functions Emulator**: Port `5001`
- **Storage Emulator**: Port `9199`
- **Emulator UI Dashboard**: Port `4000`

---

## 2. Starting Emulators
From the root project directory, run:
```bash
firebase emulators:start
```
To persist mock database data across emulator restarts:
```bash
firebase emulators:start --import=./emulator_data --export-on-exit
```

---

## 3. Connecting Flutter App to Local Emulators
To instruct the Flutter client to connect to local emulators during development:

```dart
if (kDebugMode) {
  FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
  FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
  FirebaseStorage.instance.useStorageEmulator('localhost', 9199);
}
```

---

## 4. Emulator UI Dashboard
Access `http://localhost:4000` in your web browser to visually inspect:
- Created user accounts in Auth Emulator.
- Live Firestore documents and collections.
- Trigger logs for Cloud Functions.
- Uploaded profile images in Storage Emulator.
