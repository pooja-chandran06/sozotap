# Firebase Provisioning & Setup Guide for SOZOTAP

This document details how to initialize and configure Firebase services for SOZOTAP in development, staging, and production environments.

---

## 1. Firebase Project Creation
1. Go to [Firebase Console](https://console.firebase.google.com/).
2. Click **Add project** and name it `sozotap-production` (or `sozotap-dev`).
3. Enable Google Analytics (recommended for production crashlytics).

---

## 2. Authentication Setup
1. In Firebase Console -> **Build** -> **Authentication**:
   - Enable **Email/Password** provider.
   - Enable **Google Sign-In** provider (add support email and project public name).
2. Add Authorized Domains for web app:
   - `vitanexus.web.app`
   - `sozotap.page.link`
   - `localhost`

---

## 3. Cloud Firestore Provisioning
1. In Firebase Console -> **Build** -> **Firestore Database**:
   - Click **Create Database**.
   - Choose location (e.g. `us-central` or `asia-south1`).
   - Start in **Production mode**.
2. Deploy Security Rules:
   ```bash
   firebase deploy --only firestore:rules
   ```
3. Deploy Composite Indexes:
   ```bash
   firebase deploy --only firestore:indexes
   ```

---

## 4. Firebase Storage Provisioning
1. In Firebase Console -> **Build** -> **Storage**:
   - Click **Get Started**.
   - Choose default bucket location.
2. Deploy Storage Rules:
   ```bash
   firebase deploy --only storage
   ```

---

## 5. Firebase App Check Provisioning
1. In Firebase Console -> **Build** -> **App Check**:
   - Select **Android** app.
   - Attestation Provider: **Play Integrity**.
   - Add SHA-256 fingerprint of production release key.
   - Add Debug Tokens for developer test devices.
