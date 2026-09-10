import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/notification_providers.dart';
import '../../domain/models/notification_item.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsStreamProvider);
    final unreadCount = ref.watch(unreadNotificationCountProvider);
    final repository = ref.watch(notificationRepositoryProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1C1E),
        elevation: 0,
        title: const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          if (unreadCount > 0)
            TextButton.icon(
              onPressed: () => repository.markAllAsRead(),
              icon: const Icon(Icons.done_all, color: Color(0xFF0A84FF), size: 18),
              label: const Text(
                'Mark Read',
                style: TextStyle(color: Color(0xFF0A84FF), fontWeight: FontWeight.bold),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            onPressed: () => context.push('/notification-settings'),
          ),
        ],
      ),
      body: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.notifications_off_outlined, size: 48, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No notifications yet',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Emergency alerts and system updates will appear here.',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.refresh(notificationsStreamProvider),
            color: const Color(0xFF0A84FF),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final item = notifications[index];
                return _NotificationTile(
                  item: item,
                  onTap: () {
                    if (!item.isRead) {
                      repository.markAsRead(item.notificationId);
                    }
                    if (item.alertId != null && item.alertId!.isNotEmpty) {
                      context.push('/sos-alert/${item.alertId}');
                    }
                  },
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF0A84FF))),
        error: (err, stack) => Center(
          child: Text('Error loading notifications: $err', style: const TextStyle(color: Colors.red)),
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationItem item;
  final VoidCallback onTap;

  const _NotificationTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isSos = item.type == 'sos_alert';
    final isResolved = item.type == 'sos_resolved';

    final iconColor = isSos
        ? const Color(0xFFFF3B30)
        : (isResolved ? const Color(0xFF30D158) : const Color(0xFF0A84FF));

    final iconData = isSos
        ? Icons.warning_amber_rounded
        : (isResolved ? Icons.check_circle_outline_rounded : Icons.info_outline_rounded);

    final formattedTime = DateFormat('MMM d, h:mm a').format(item.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: item.isRead ? const Color(0xFF1C1C1E) : const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: item.isRead ? Colors.transparent : iconColor.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(iconData, color: iconColor, size: 24),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                item.title,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: item.isRead ? FontWeight.normal : FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
            if (!item.isRead)
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: iconColor, shape: BoxShape.circle),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              item.body,
              style: TextStyle(color: Colors.grey[400], fontSize: 13),
            ),
            const SizedBox(height: 6),
            Text(
              formattedTime,
              style: TextStyle(color: Colors.grey[600], fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
