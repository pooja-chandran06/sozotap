class AppConfig {
  /// The base URL for HTTP-based SOS Cloud Functions.
  static const String smsCloudFunctionUrl = 'https://us-central1-sozotap-production.cloudfunctions.net/sendSms';

  /// The Firestore collection name used by the Firebase Trigger SMS extension.
  static const String firestoreSmsCollection = 'messages';
  
  /// The Firestore collection name used by the Firebase Trigger Email extension.
  static const String firestoreEmailCollection = 'emails';

  /// The Firestore collection name used for queuing FCM Push Notifications.
  static const String firestorePushCollection = 'push_notifications';
}
