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

### Response (403 Forbidden - Access Disabled):
```json
{
  "status": "disabled",
  "message": "Emergency medical access has been disabled by the user."
}
```

---

## 2. `rotateEmergencyQrToken`
- **Type**: HTTPS Callable
- **Authentication**: Requires Firebase Auth (User session token)

### Request Payload:
```json
{}
```

### Response (200 OK):
```json
{
  "status": "success",
  "message": "QR token rotated successfully.",
  "token": "sozo_live_9876543210fedcba0987654321fedcba"
}
```

---

## 3. `deleteUserAccount`
- **Type**: HTTPS Callable
- **Authentication**: Requires Firebase Auth (User session token)

### Request Payload:
```json
{}
```

### Response (200 OK):
```json
{
  "status": "success",
  "message": "User account and all associated medical data purged successfully."
}
```
