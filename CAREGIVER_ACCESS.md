# SOZOTAP Caregiver Access Specification

This document describes the caregiver invitation lifecycle, permission scopes, and Firestore security rules enforcing patient privacy.

---

## 1. Invitation Lifecycle
```
[Patient: Invite Caregiver by Email]
         │
         ▼ (status: "pending")
[Caregiver: Notification Received]
         │
         ├───► [Accept] ───► (status: "accepted") ───► Grants configured permissions
         │
         └───► [Decline] ──► (status: "declined") ───► Access denied
```

---

## 2. Granular Caregiver Permissions
Patients explicitly select permissions during invitation (`/caregivers/invite`):
- `viewEmergencySummary`: View blood group, allergies, conditions during SOS alert.
- `receiveSosAlerts`: Receive high-priority push & SMS notifications when SOS triggers.
- `viewActiveSosLocation`: View real-time GPS coordinates during active SOS alerts.
- `manageEmergencyContacts`: Edit emergency contacts list (default: `false`).

---

## 3. Firestore Rule Enforcements
Firestore rules restrict document access:
- Caregivers can read `/caregiver_relationships` only where `caregiverUserId == request.auth.uid`.
- Caregivers **cannot** modify or delete patient medical profiles, auth credentials, or storage files.
