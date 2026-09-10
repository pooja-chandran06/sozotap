enum Relationship { family, friend, colleague, doctor, other }

class EmergencyContact {
  final String id;
  final String userId;
  final String? recipientUserId; // Linked SOZOTAP user ID of the contact for FCM push dispatch
  final String name;
  final Relationship relationship;
  final String phoneNumber;
  final String? countryCode;
  final int priority;
  final bool isPrimary;
  final bool canCall;
  final bool canSms;
  final bool allowPushNotifications;
  final bool allowSmsNotifications;
  final DateTime? smsConsentAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const EmergencyContact({
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
    this.allowPushNotifications = true,
    this.allowSmsNotifications = false,
    this.smsConsentAt,
    required this.createdAt,
    required this.updatedAt,
  });

  String get contactId => id;
  String get ownerUserId => userId;

  EmergencyContact copyWith({
    String? id,
    String? userId,
    String? recipientUserId,
    String? name,
    Relationship? relationship,
    String? phoneNumber,
    String? countryCode,
    int? priority,
    bool? isPrimary,
    bool? canCall,
    bool? canSms,
    bool? allowPushNotifications,
    bool? allowSmsNotifications,
    DateTime? smsConsentAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EmergencyContact(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      recipientUserId: recipientUserId ?? this.recipientUserId,
      name: name ?? this.name,
      relationship: relationship ?? this.relationship,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      countryCode: countryCode ?? this.countryCode,
      priority: priority ?? this.priority,
      isPrimary: isPrimary ?? this.isPrimary,
      canCall: canCall ?? this.canCall,
      canSms: canSms ?? this.canSms,
      allowPushNotifications: allowPushNotifications ?? this.allowPushNotifications,
      allowSmsNotifications: allowSmsNotifications ?? this.allowSmsNotifications,
      smsConsentAt: smsConsentAt ?? this.smsConsentAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
