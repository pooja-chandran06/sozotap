// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'emergency_contact_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EmergencyContactDto _$EmergencyContactDtoFromJson(Map<String, dynamic> json) =>
    EmergencyContactDto(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      relationship: json['relationship'] as String? ?? 'other',
      phoneNumber: json['phoneNumber'] as String? ?? '',
      countryCode: json['countryCode'] as String?,
      priority: (json['priority'] as num?)?.toInt() ?? 0,
      canCall: json['canCall'] as bool? ?? true,
      canSms: json['canSms'] as bool? ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
    );

Map<String, dynamic> _$EmergencyContactDtoToJson(EmergencyContactDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'name': instance.name,
      'relationship': instance.relationship,
      'phoneNumber': instance.phoneNumber,
      'countryCode': instance.countryCode,
      'priority': instance.priority,
      'canCall': instance.canCall,
      'canSms': instance.canSms,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
