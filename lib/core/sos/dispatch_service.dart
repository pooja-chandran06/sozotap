enum NotificationChannel { sms, email, push, apiDispatch, both, all }

abstract class DispatchService {
  /// Dispatches a notification and returns the unique message ID for status tracking.
  Future<String> sendNotification({
    required String to,
    required NotificationChannel channel,
    String? subject,
    required String body,
    Map<String, dynamic>? metadata,
  });
}
