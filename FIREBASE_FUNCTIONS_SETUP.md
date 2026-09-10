# Firebase Cloud Functions v2 Setup & Secrets Guide

This document explains how to build, test, configure secrets, and deploy Firebase Cloud Functions v2 for SOZOTAP.

---

## 1. Cloud Functions Architecture
The backend services reside in `functions/` built using Node.js 18, TypeScript, and Firebase Functions v2 SDK.

### Primary Cloud Functions Endpoints:
- `sendEmergencyAlert`: Firestore onCreate trigger on `/emergency_alerts/{alertId}`. Dispatches FCM push notifications to priority contacts and invokes SMS fallback engine.
- `resolveEmergencyQr`: HTTPS Callable / REST API endpoint (`/resolveEmergencyQr`). Resolves dynamic QR tokens for paramedics and applies user privacy consent filters.
- `rotateEmergencyQrToken`: HTTPS Callable endpoint. Rotates or revokes dynamic QR tokens on demand.
- `deleteUserAccount`: HTTPS Callable endpoint. Deletes all user data from Auth, Firestore, and Storage.

---

## 2. Setting Up Secrets in Firebase Secret Manager

SOZOTAP Cloud Functions use Firebase Secret Manager for Twilio SMS integration:

```bash
# Set Twilio Account SID
firebase functions:secrets:set TWILIO_ACCOUNT_SID

# Set Twilio Auth Token
firebase functions:secrets:set TWILIO_AUTH_TOKEN

# Set Twilio Phone Number
firebase functions:secrets:set TWILIO_PHONE_NUMBER
```

---

## 3. Local Development & Testing
```bash
cd functions

# Install dependencies
npm ci

# Run TypeScript linter
npm run lint

# Compile TypeScript
npm run build

# Run unit tests
npm test
```

---

## 4. Deployment
To deploy Cloud Functions to Firebase production:
```bash
firebase deploy --only functions
```
