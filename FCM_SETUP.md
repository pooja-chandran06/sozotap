# Firebase Cloud Messaging (FCM) Setup Guide

This document outlines FCM setup for client apps, Android 13+ permission compliance, and device token lifecycles.

---

## 📱 FCM Client Registration Lifecycle

1. **Authentication**: After user authentication (phone or email), `FcmService.registerDeviceToken()` is called.
2. **Permission Check**: Requests permission using `FirebaseMessaging.instance.requestPermission()`.
3. **Firestore Synchronization**: FCM tokens are saved in:
   `users/{uid}/device_tokens/{tokenId}`
4. **Token Data Schema**:
   - `tokenId`: Unique hash of FCM token
   - `ownerUserId`: User ID
   - `token`: Raw FCM registration token
   - `platform`: `android` | `ios` | `web`
   - `appVersion`: App version string
   - `notificationPermissionStatus`: `authorized` | `denied` | `provisional`
   - `enabled`: `true` (automatically set to `false` by backend if token becomes invalid/unregistered)
   - `lastSeenAt`: Timestamp of registration

---

## 🔔 Foreground & Background Message Handling

- **Foreground**: Presented using `flutter_local_notifications` with channel ID `emergency_sos_channel` (Importance: Max, Sound: Default).
- **Background / Terminated**: Handled via `firebaseMessagingBackgroundHandler`. Clicking the notification routes the app to `/sos-alert/{alertId}` via `GoRouter`.

---

## 🛡 Android 13+ (API 33+) Permission Compliance

For Android 13+, POST_NOTIFICATIONS permission must be granted by the user. SOZOTAP presents an educational banner in `NotificationSettingsScreen` explaining the necessity of emergency alerts before triggering native OS permission prompts.

---

## 🔒 Privacy Guarantee
- FCM payload titles and bodies MUST NOT contain medical conditions, diagnoses, medications, allergies, or raw GPS coordinates.
- Safe payload format:
  - Title: `SOS Alert`
  - Body: `A trusted contact may need help. Tap to view the alert.`
  - Data: `{ "type": "sos_alert", "alertId": "...", "route": "/sos-alert/..." }`
