# Offline Support & Synchronization Architecture

SOZOTAP implements a hybrid offline strategy combining Firestore native persistence with explicit Hive local caching and connectivity monitoring.

---

## 🔒 Security & Namespace Isolation Rules

1. **User Isolation**: Hive boxes are namespaced using the authenticated User ID (`user_<uid>_profile`, `user_<uid>_contacts`, `user_<uid>_qr_metadata`).
2. **Secrets Omission**: Raw secret QR tokens (`rawToken`), FCM server keys, and account passwords are **NEVER** stored in offline cache. Only non-sensitive QR metadata (`displayEmergencyId`, `status`, `expiresAt`) is cached.
3. **Logout Sanitization**: On user sign-out (`authRepository.signOut()`), `HiveCacheService.clearUserCache(uid)` deletes local boxes for that user.

---

## 📶 Connectivity Detection & Status Banner

- `ConnectivityService` uses `connectivity_plus` to monitor physical signal and `internet_connection_checker_plus` to verify actual reachability.
- When offline:
  - `isOfflineProvider` emits `true`.
  - `OfflineBannerWidget` appears at the top of the UI displaying **"Offline Mode — Displaying cached data"** and the **"Last synced"** timestamp.
- SOS emergency activation requires live dispatch. If offline, the app instructs the user to initiate a direct cellular call (`tel:112` or `tel:911`).
