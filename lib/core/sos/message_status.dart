import 'package:json_annotation/json_annotation.dart';

part 'message_status.g.dart';

enum MessageStatus { queued, processing, success, failure }

@JsonSerializable()
class MessageDeliveryStatus {
  final String messageId;
  final String userId;
  final String recipient;
  final MessageStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? errorMessage;
  final String channel;

  const MessageDeliveryStatus({
    required this.messageId,
    required this.userId,
    required this.recipient,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.errorMessage,
    required this.channel,
  });

  factory MessageDeliveryStatus.fromJson(Map<String, dynamic> json) => _$MessageDeliveryStatusFromJson(json);
  Map<String, dynamic> toJson() => _$MessageDeliveryStatusToJson(this);
}
