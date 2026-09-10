# Account Controls & Deletion Guide

This document details user account controls, password reset flows, and protected account deletion architecture.

---

## 🔒 Protected Cloud Function Account Deletion

Account deletion is a destructive operation that MUST NOT rely solely on client-side Firestore deletes.

### Protocol Steps:
1. **User Request**: User opens `AccountScreen` and taps **Delete Account & Cloud Data**.
2. **Re-authentication**: User enters account password to verify identity.
3. **Explicit Phrase Confirmation**: User must manually type **`DELETE`** in all caps into a confirmation input field.
4. **Local Cache Purge**: Client executes `HiveCacheService.clearUserCache(uid)` to wipe local device storage.
5. **Backend Cloud Function Dispatch**: Client invokes protected callable Cloud Function `deleteUserAccount`:
   - Revokes and deletes owner `emergency_qr_tokens`.
   - Deletes `medical_profiles/{uid}` document.
   - Deletes `users/{uid}/emergency_contacts/*` subcollection.
   - Deletes `users/{uid}/device_tokens/*` subcollection.
   - Deletes `users/{uid}/notification_preferences/*` subcollection.
   - Deletes `users/{uid}/privacy_settings/*` subcollection.
   - Deletes `users/{uid}` root user record.
   - Erases uploaded profile photo from Firebase Storage (`users/{uid}/profile_photo.jpg`).
   - Deletes the Firebase Auth account (`auth.deleteUser(uid)`).
6. **Sign-out & Navigation**: Client signs out and redirects to `/login`.
