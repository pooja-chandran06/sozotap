import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../constants/app_colors.dart';
import '../domain/models/in_app_notification_model.dart';
import '../providers/notification_providers.dart';

class NotificationInboxScreen extends ConsumerWidget {
  const NotificationInboxScreen({super.key});

  Future<void> _markAsRead(String notificationId) async {
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      // Ignored non-fatal
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(inAppNotificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notification Inbox',
          style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.notifications_off_outlined, size: 72, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Emergency alerts and notifications will appear here.',
                    style: TextStyle(fontSize: 13, color: Colors.grey, fontFamily: 'Poppins'),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16.0),
            itemCount: notifications.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _buildNotificationCard(context, notification);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Failed to load notifications: $err')),
      ),
    );
  }

  Widget _buildNotificationCard(BuildContext context, InAppNotificationModel notification) {
    final bool isUnread = !notification.isRead;

    return Card(
      elevation: isUnread ? 3 : 1,
      color: isUnread ? Colors.red.shade50 : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: isUnread ? const BorderSide(color: AppColors.primary, width: 1.5) : BorderSide.none,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: notification.type == 'sos_alert' ? AppColors.primary : AppColors.accent,
          child: Icon(
            notification.type == 'sos_alert' ? Icons.warning_rounded : Icons.notifications_rounded,
            color: Colors.white,
          ),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
            fontFamily: 'Poppins',
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              notification.body,
              style: const TextStyle(fontSize: 13, fontFamily: 'Poppins'),
            ),
            const SizedBox(height: 8),
            Text(
              DateFormat.yMMMd().add_jm().format(notification.createdAt),
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontFamily: 'Poppins'),
            ),
          ],
        ),
        trailing: isUnread
            ? const Icon(Icons.circle, color: AppColors.primary, size: 12)
            : null,
        onTap: () {
          _markAsRead(notification.notificationId);
          if (notification.alertId != null && notification.alertId!.isNotEmpty) {
            context.push('/sos-active/${notification.alertId}');
          }
        },
      ),
    );
  }
}
