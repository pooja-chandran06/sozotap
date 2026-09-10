# SOZOTAP Backend API Documentation

This document describes the Cloud Functions v2 backend endpoints, request payloads, response structures, and authorization requirements.

---

## 1. `resolveEmergencyQr`
- **Type**: HTTPS Callable / REST Endpoint
- **URL**: `https://<region>-<project-id>.cloudfunctions.net/resolveEmergencyQr`
- **Authentication**: Public (high-entropy token authorization)

### Request Payload:
```json
{
  "token": "sozo_live_a1b2c3d4e5f678901234567890abcdef"
}
```

### Response (200 OK):
```json
{
  "status": "success",
  "data": {
    "fullName": "Jane Doe",
    "bloodGroup": "O Positive",
    "allergies": ["Penicillin", "Peanuts"],
    "medicalConditions": ["Asthma"],
    "medications": ["Albuterol Inhaler"],
    "emergencyContacts": [
      {
        "name": "John Doe",
        "phone": "+14155552671",
        "relationship": "Spouse"
      }
    ]
  }
}
```

---

## 2. `createDevicePairingSession`
- **Type**: HTTPS Callable
- **Authentication**: Requires Firebase Auth

### Request Payload:
```json
{
  "deviceType": "esp32_wifi"
}
```

### Response (200 OK):
```json
{
  "sessionId": "pair_a1b2c3d4e5f67890",
  "challengeCode": "654321",
  "expiresAt": "2026-09-10T16:15:00.000Z"
}
```

---

## 3. `completeDevicePairing`
- **Type**: HTTPS Callable
- **Authentication**: Requires Firebase Auth

### Request Payload:
```json
{
  "sessionId": "pair_a1b2c3d4e5f67890",
  "challengeCode": "654321",
  "displayName": "Kitchen SOS Button",
  "connectionType": "wifi"
}
```

### Response (200 OK):
```json
{
  "deviceId": "dev_a1b2c3d4e5f67890",
  "secretToken": "sozo_sec_9876543210fedcba",
  "pairedAt": "2026-09-10T16:00:00.000Z"
}
```

---

## 4. `ingestDeviceEvent`
- **Type**: HTTPS Callable / REST Endpoint
- **Authentication**: Secret Token Verification

### Request Payload:
```json
{
  "data": {
    "deviceId": "dev_esp32_001",
    "secretToken": "sozo_sec_9876543210fedcba",
    "eventId": "evt_1700000000",
    "eventType": "sos_pressed",
    "batteryLevel": 95
  }
}
```

### Response (200 OK):
```json
{
  "status": "processed",
  "eventId": "evt_1700000000"
}
```

---

## 5. `createCaregiverInvitation`
- **Type**: HTTPS Callable
- **Authentication**: Requires Firebase Auth

### Request Payload:
```json
{
  "caregiverEmail": "caregiver@example.com",
  "permissions": {
    "viewEmergencySummary": true,
    "receiveSosAlerts": true,
    "viewActiveSosLocation": true,
    "manageEmergencyContacts": false
  }
}
```

### Response (200 OK):
```json
{
  "success": true,
  "relationshipId": "rel_owner123_caregiver456"
}
```
