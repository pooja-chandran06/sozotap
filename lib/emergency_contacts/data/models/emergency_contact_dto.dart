import 'package:json_annotation/json_annotation.dart';
import '../../domain/models/emergency_contact.dart';

part 'emergency_contact_dto.g.dart';

@JsonSerializable()
class EmergencyContactDto {
  final String id;
  final String userId;
  final String name;
  final String relationship;
  final String phoneNumber;
  final String? countryCode;
  final int priority;
  final bool canCall;
  final bool canSms;
  final DateTime createdAt;
  final DateTime updatedAt;

  const EmergencyContactDto({
    required this.id,
    required this.userId,
    required this.name,
    required this.relationship,
    required this.phoneNumber,
    this.countryCode,
    required this.priority,
    required this.canCall,
    required this.canSms,
    required this.createdAt,
    required this.updatedAt,
  });

  factory EmergencyContactDto.fromJson(Map<String, dynamic> json) => _$EmergencyContactDtoFromJson(json);

  Map<String, dynamic> toJson() => _$EmergencyContactDtoToJson(this);

  factory EmergencyContactDto.fromDomain(EmergencyContact contact) {
    return EmergencyContactDto(
      id: contact.id,
      userId: contact.userId,
      name: contact.name,
      relationship: contact.relationship.name,
      phoneNumber: contact.phoneNumber,
      countryCode: contact.countryCode,
      priority: contact.priority,
      canCall: contact.canCall,
      canSms: contact.canSms,
      createdAt: contact.createdAt,
      updatedAt: contact.updatedAt,
    );
  }

  EmergencyContact toDomain() {
    return EmergencyContact(
      id: id,
      userId: userId,
      name: name,
      relationship: Relationship.values.firstWhere(
        (e) => e.name == relationship,
        orElse: () => Relationship.other,
      ),
      phoneNumber: phoneNumber,
      countryCode: countryCode,
      priority: priority,
      canCall: canCall,
      canSms: canSms,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
