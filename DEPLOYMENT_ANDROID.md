# SOZOTAP Android Deployment & Release Guide

This document outlines the step-by-step procedure for packaging, signing, and releasing the SOZOTAP Android application for Google Play Store and staging environments.

---

## 1. Prerequisites
- **Flutter SDK**: `3.22.x` stable channel or higher.
- **Java JDK**: Version 17 (`zulu` or OpenJDK).
- **Android Studio**: Recommended with Android SDK platform tools (API Level 34+).
- **Google Play Console Account**: For production and internal testing tracks.
- **Firebase Console Project Access**: Production & Staging projects.

---

## 2. Android Release Signing Setup

### A. Generate Upload Keystore
If an upload keystore has not been generated yet, run the following command:
```bash
keytool -genkey -v -keystore android/upload-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias sozotap-release-key
```

### B. Configure `key.properties`
Copy `key.properties.example` to `android/key.properties`:
```bash
cp key.properties.example android/key.properties
```
Fill in the exact values:
```ini
storePassword=YOUR_ACTUAL_STORE_PASSWORD
keyPassword=YOUR_ACTUAL_KEY_PASSWORD
keyAlias=sozotap-release-key
storeFile=../upload-keystore.jks
```
> **SECURITY WARNING**: Never commit `android/key.properties` or `*.jks` files to Git repository!

---

## 3. Firebase App Check Configuration

1. In the **Firebase Console** -> **App Check**:
   - Register your Android app with **Play Integrity** provider.
   - Obtain the SHA-256 fingerprint of your release keystore using:
     ```bash
     keytool -list -v -keystore android/upload-keystore.jks -alias sozotap-release-key
     ```
   - Add the SHA-256 fingerprint to Firebase App Check and Firebase Auth configuration.

---

## 4. Build Production App Bundle (AAB)

To create an Android App Bundle for Google Play Console:
```bash
# Clean previous build artifacts
flutter clean
flutter pub get

# Build Release Android App Bundle
flutter build appbundle --release --build-number=1 --build-name=1.0.0
```

The output file will be generated at:
`build/app/outputs/bundle/release/app-release.aab`

To create an APK for manual internal testing:
```bash
flutter build apk --release
```
Output: `build/app/outputs/flutter-apk/app-release.apk`

---

## 5. Firebase Cloud Functions Deployment

Navigate to the functions folder and deploy to production:
```bash
cd functions
npm ci
npm run build
npm test
firebase deploy --only functions
```

Deploy Firestore Security Rules & Indexes:
```bash
firebase deploy --only firestore:rules,firestore:indexes
```

Deploy Storage Security Rules:
```bash
firebase deploy --only storage
```

---

## 6. Google Play Store Submission Checklist
1. **Internal Testing**: Upload `app-release.aab` to Google Play Console Internal Track.
2. **App Permissions Audit**:
   - Camera (`android.permission.CAMERA`) for QR code scanning.
   - Location (`ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`) for SOS dispatch.
   - Foreground Service (`FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_LOCATION`) for active emergency alerts.
   - Post Notifications (`POST_NOTIFICATIONS`) for Android 13+ alerts.
3. **Data Safety Declarations**:
   - Personal Info (Name, Email, Phone) -> Collected for account & emergency contact dispatch.
   - Health Info (Blood group, Allergies, Medical Conditions) -> Collected for user-controlled paramedic emergency access.
   - Location -> Collected during active SOS events for emergency response.
4. **App Privacy Policy**: Link to `https://vitanexus.web.app/privacy.html`.
