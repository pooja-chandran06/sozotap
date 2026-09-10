import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationItem {
  final String notificationId;
  final String recipientUserId;
  final String senderUserId;
  final String title;
  final String body;
  final String type; // sos_alert, sos_resolved, system
  final String? alertId;
  final bool isRead;
  final DateTime createdAt;

  NotificationItem({
    required this.notificationId,
    required this.recipientUserId,
    required this.senderUserId,
    required this.title,
    required this.body,
    required this.type,
    this.alertId,
    this.isRead = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'notificationId': notificationId,
      'recipientUserId': recipientUserId,
      'senderUserId': senderUserId,
      'title': title,
      'body': body,
      'type': type,
      'alertId': alertId,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory NotificationItem.fromMap(Map<String, dynamic> map, String id) {
    return NotificationItem(
      notificationId: id,
      recipientUserId: map['recipientUserId'] ?? '',
      senderUserId: map['senderUserId'] ?? '',
      title: map['title'] ?? 'Notification',
      body: map['body'] ?? '',
      type: map['type'] ?? 'system',
      alertId: map['alertId'],
      isRead: map['isRead'] ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  NotificationItem copyWith({
    String? notificationId,
    String? recipientUserId,
    String? senderUserId,
    String? title,
    String? body,
    String? type,
    String? alertId,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return NotificationItem(
      notificationId: notificationId ?? this.notificationId,
      recipientUserId: recipientUserId ?? this.recipientUserId,
      senderUserId: senderUserId ?? this.senderUserId,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      alertId: alertId ?? this.alertId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
