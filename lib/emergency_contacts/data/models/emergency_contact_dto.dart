import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/emergency_contact.dart';

class EmergencyContactDto {
  final String id;
  final String userId;
  final String? recipientUserId;
  final String name;
  final String relationship;
  final String phoneNumber;
  final String? countryCode;
  final int priority;
  final bool isPrimary;
  final bool canCall;
  final bool canSms;
  final DateTime createdAt;
  final DateTime updatedAt;

  const EmergencyContactDto({
    required this.id,
    required this.userId,
    this.recipientUserId,
    required this.name,
    required this.relationship,
    required this.phoneNumber,
    this.countryCode,
    required this.priority,
    this.isPrimary = false,
    required this.canCall,
    required this.canSms,
    required this.createdAt,
    required this.updatedAt,
  });

  String get contactId => id;
  String get ownerUserId => userId;

  factory EmergencyContactDto.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    final int priorityVal = (json['priority'] as num?)?.toInt() ?? 0;
    final bool isPrimaryVal = json['isPrimary'] as bool? ?? (priorityVal == 1);
    final String cId = json['contactId'] as String? ?? json['id'] as String? ?? '';
    final String uId = json['ownerUserId'] as String? ?? json['userId'] as String? ?? '';

    return EmergencyContactDto(
      id: cId,
      userId: uId,
      recipientUserId: json['recipientUserId'] as String?,
      name: json['name'] as String? ?? '',
      relationship: json['relationship'] as String? ?? 'other',
      phoneNumber: json['phoneNumber'] as String? ?? '',
      countryCode: json['countryCode'] as String?,
      priority: priorityVal,
      isPrimary: isPrimaryVal,
      canCall: json['canCall'] as bool? ?? true,
      canSms: json['canSms'] as bool? ?? true,
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'contactId': id,
        'userId': userId,
        'ownerUserId': userId,
        'recipientUserId': recipientUserId,
        'name': name,
        'relationship': relationship,
        'phoneNumber': phoneNumber,
        'countryCode': countryCode,
        'priority': priority,
        'isPrimary': isPrimary,
        'canCall': canCall,
        'canSms': canSms,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory EmergencyContactDto.fromDomain(EmergencyContact contact) {
    return EmergencyContactDto(
      id: contact.id,
      userId: contact.userId,
      recipientUserId: contact.recipientUserId,
      name: contact.name,
      relationship: contact.relationship.name,
      phoneNumber: contact.phoneNumber,
      countryCode: contact.countryCode,
      priority: contact.priority,
      isPrimary: contact.isPrimary,
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
      recipientUserId: recipientUserId,
      name: name,
      relationship: Relationship.values.firstWhere(
        (e) => e.name == relationship,
        orElse: () => Relationship.other,
      ),
      phoneNumber: phoneNumber,
      countryCode: countryCode,
      priority: priority,
      isPrimary: isPrimary,
      canCall: canCall,
      canSms: canSms,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

