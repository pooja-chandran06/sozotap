import 'package:cloud_firestore/cloud_firestore.dart';

class InAppNotificationModel {
  final String notificationId;
  final String recipientUserId;
  final String senderUserId;
  final String title;
  final String body;
  final String type; // 'sos_alert', 'sos_resolved', etc.
  final String? alertId;
  final bool isRead;
  final DateTime createdAt;

  const InAppNotificationModel({
    required this.notificationId,
    required this.recipientUserId,
    required this.senderUserId,
    required this.title,
    required this.body,
    required this.type,
    this.alertId,
    required this.isRead,
    required this.createdAt,
  });

  Map<String, dynamic> toFirestore() {
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

  factory InAppNotificationModel.fromFirestore(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>? ?? {};
    return InAppNotificationModel.fromMap(map, id: doc.id);
  }

  factory InAppNotificationModel.fromMap(Map<String, dynamic> map, {String? id}) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return InAppNotificationModel(
      notificationId: id ?? (map['notificationId'] as String? ?? ''),
      recipientUserId: map['recipientUserId'] as String? ?? '',
      senderUserId: map['senderUserId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      type: map['type'] as String? ?? 'sos_alert',
      alertId: map['alertId'] as String?,
      isRead: map['isRead'] as bool? ?? false,
      createdAt: parseDate(map['createdAt']),
    );
  }
}
