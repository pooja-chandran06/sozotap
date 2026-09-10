import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/notification_repository.dart';
import '../../domain/models/notification_item.dart';
import '../../services/fcm_service.dart';
import '../../../models/notification_preference.dart';
import '../../../models/device_token.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository();
});

final fcmServiceProvider = Provider<FcmService>((ref) {
  return FcmService();
});

final notificationsStreamProvider = StreamProvider<List<NotificationItem>>((ref) {
  final repository = ref.watch(notificationRepositoryProvider);
  return repository.getNotificationsStream();
});

final unreadNotificationCountProvider = Provider<int>((ref) {
  final notificationsAsync = ref.watch(notificationsStreamProvider);
  return notificationsAsync.maybeWhen(
    data: (items) => items.where((item) => !item.isRead).length,
    orElse: () => 0,
  );
});

final notificationPreferencesStreamProvider = StreamProvider<NotificationPreference>((ref) {
  final repository = ref.watch(notificationRepositoryProvider);
  return repository.getNotificationPreferencesStream();
});

final deviceTokensStreamProvider = StreamProvider<List<DeviceToken>>((ref) {
  final repository = ref.watch(notificationRepositoryProvider);
  return repository.getDeviceTokensStream();
});
