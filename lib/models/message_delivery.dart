import 'package:cloud_firestore/cloud_firestore.dart';

class MessageDelivery {
  final String deliveryId;
  final String alertId;
  final String? recipientUserId;
  final String recipientContactId;
  final String channel; // fcm, sms
  final String status; // queued, sent, delivered, failed, skipped
  final String? providerMessageId;
  final String? failureCode;
  final String? failureReason;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String idempotencyKey;

  MessageDelivery({
    required this.deliveryId,
    required this.alertId,
    this.recipientUserId,
    required this.recipientContactId,
    required this.channel,
    required this.status,
    this.providerMessageId,
    this.failureCode,
    this.failureReason,
    required this.createdAt,
    required this.updatedAt,
    required this.idempotencyKey,
  });

  factory MessageDelivery.fromMap(Map<String, dynamic> map, String id) {
    return MessageDelivery(
      deliveryId: id,
      alertId: map['alertId'] ?? '',
      recipientUserId: map['recipientUserId'],
      recipientContactId: map['recipientContactId'] ?? '',
      channel: map['channel'] ?? 'fcm',
      status: map['status'] ?? 'queued',
      providerMessageId: map['providerMessageId'],
      failureCode: map['failureCode'],
      failureReason: map['failureReason'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      idempotencyKey: map['idempotencyKey'] ?? '',
    );
  }
}
