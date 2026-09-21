// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_status.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MessageDeliveryStatus _$MessageDeliveryStatusFromJson(
        Map<String, dynamic> json) =>
    MessageDeliveryStatus(
      messageId: json['messageId'] as String,
      userId: json['userId'] as String,
      recipient: json['recipient'] as String,
      status: $enumDecode(_$MessageStatusEnumMap, json['status']),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
      errorMessage: json['errorMessage'] as String?,
      channel: json['channel'] as String,
    );

Map<String, dynamic> _$MessageDeliveryStatusToJson(
        MessageDeliveryStatus instance) =>
    <String, dynamic>{
      'messageId': instance.messageId,
      'userId': instance.userId,
      'recipient': instance.recipient,
      'status': _$MessageStatusEnumMap[instance.status]!,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
      'errorMessage': instance.errorMessage,
      'channel': instance.channel,
    };

const _$MessageStatusEnumMap = {
  MessageStatus.queued: 'queued',
  MessageStatus.processing: 'processing',
  MessageStatus.success: 'success',
  MessageStatus.failure: 'failure',
};
