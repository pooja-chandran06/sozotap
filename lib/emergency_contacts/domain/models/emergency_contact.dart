enum Relationship { family, friend, colleague, doctor, other }

class EmergencyContact {
  final String id;
  final String userId;
  final String name;
  final Relationship relationship;
  final String phoneNumber;
  final String? countryCode;
  final int priority;
  final bool canCall;
  final bool canSms;
  final DateTime createdAt;
  final DateTime updatedAt;

  const EmergencyContact({
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

  EmergencyContact copyWith({
    String? id,
    String? userId,
    String? name,
    Relationship? relationship,
    String? phoneNumber,
    String? countryCode,
    int? priority,
    bool? canCall,
    bool? canSms,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EmergencyContact(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      relationship: relationship ?? this.relationship,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      countryCode: countryCode ?? this.countryCode,
      priority: priority ?? this.priority,
      canCall: canCall ?? this.canCall,
      canSms: canSms ?? this.canSms,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
