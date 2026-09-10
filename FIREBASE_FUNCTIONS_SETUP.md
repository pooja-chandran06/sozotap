# Firebase Cloud Functions Setup Guide

This guide describes how to configure, build, test, and deploy the SOZOTAP Cloud Functions v2 backend.

---

## 🛠 Dependencies & Prerequisites
- Node.js `18`
- Firebase Tools CLI (`npm install -g firebase-tools`)
- TypeScript `5.3+`

---

## 📂 Project Directory Structure
```
functions/
├── src/
│   ├── config.ts              # Firebase Params secrets definitions
│   ├── types.ts               # Core backend data interfaces
│   ├── services/
│   │   ├── fcm_service.ts     # Firebase Admin SDK FCM sendEach handler
│   │   ├── sms_service.ts     # Twilio / Disabled SMS Provider implementation
│   │   ├── delivery_service.ts# Message delivery tracking in message_deliveries
│   │   └── notification_service.ts # Recipient inbox notification builder
│   ├── utils/
│   │   ├── logger.ts          # Structured logger wrapping Firebase Logger
│   │   ├── redaction.ts       # Log redaction helper for PII and medical data
│   │   └── idempotency.ts     # SHA-256 idempotency key generator
│   └── index.ts               # Firestore triggers & Callable endpoints
├── test/
│   └── functions.test.ts      # Jest unit tests for backend logic
├── package.json
├── tsconfig.json
└── jest.config.js
```

---

## 🔑 Setting Secrets via Firebase Secrets Manager

Privileged credentials (such as Twilio account SID and auth tokens) MUST NOT be saved in source code. Configure them using Firebase CLI:

```bash
# Set Twilio SMS Provider Secrets (Optional if using active Twilio SMS)
firebase functions:secrets:set SMS_PROVIDER
# Value: twilio

firebase functions:secrets:set TWILIO_ACCOUNT_SID
# Value: ACxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

firebase functions:secrets:set TWILIO_AUTH_TOKEN
# Value: your_auth_token_here

firebase functions:secrets:set TWILIO_FROM_NUMBER
# Value: +15005550006
```

---

## 🚀 Building & Deploying

### 1. Build TypeScript Source
```bash
cd functions
npm run build
```

### 2. Run Local Unit Tests
```bash
npm test
```

### 3. Start Local Emulator
```bash
npm run serve
```

### 4. Deploy to Firebase Production
```bash
firebase deploy --only functions
```
