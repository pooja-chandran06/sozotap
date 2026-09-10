enum InvitationStatus { pending, accepted, declined, revoked, expired }

class CaregiverPermissions {
  final bool viewEmergencySummary;
  final bool receiveSosAlerts;
  final bool viewActiveSosLocation;
  final bool manageEmergencyContacts;

  const CaregiverPermissions({
    this.viewEmergencySummary = true,
    this.receiveSosAlerts = true,
    this.viewActiveSosLocation = true,
    this.manageEmergencyContacts = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'viewEmergencySummary': viewEmergencySummary,
      'receiveSosAlerts': receiveSosAlerts,
      'viewActiveSosLocation': viewActiveSosLocation,
      'manageEmergencyContacts': manageEmergencyContacts,
    };
  }

  factory CaregiverPermissions.fromJson(Map<String, dynamic> json) {
    return CaregiverPermissions(
      viewEmergencySummary: json['viewEmergencySummary'] as bool? ?? true,
      receiveSosAlerts: json['receiveSosAlerts'] as bool? ?? true,
      viewActiveSosLocation: json['viewActiveSosLocation'] as bool? ?? true,
      manageEmergencyContacts: json['manageEmergencyContacts'] as bool? ?? false,
    );
  }
}

class CaregiverRelationship {
  final String relationshipId;
  final String ownerUserId;
  final String caregiverUserId;
  final String role;
  final CaregiverPermissions permissions;
  final InvitationStatus invitationStatus;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? revokedAt;

  CaregiverRelationship({
    required this.relationshipId,
    required this.ownerUserId,
    required this.caregiverUserId,
    this.role = 'Caregiver',
    required this.permissions,
    required this.invitationStatus,
    required this.createdAt,
    required this.updatedAt,
    this.revokedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'relationshipId': relationshipId,
      'ownerUserId': ownerUserId,
      'caregiverUserId': caregiverUserId,
      'role': role,
      'permissions': permissions.toJson(),
      'invitationStatus': invitationStatus.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'revokedAt': revokedAt?.toIso8601String(),
    };
  }

  factory CaregiverRelationship.fromJson(Map<String, dynamic> json) {
    return CaregiverRelationship(
      relationshipId: json['relationshipId'] as String,
      ownerUserId: json['ownerUserId'] as String,
      caregiverUserId: json['caregiverUserId'] as String,
      role: json['role'] as String? ?? 'Caregiver',
      permissions: CaregiverPermissions.fromJson(json['permissions'] as Map<String, dynamic>? ?? {}),
      invitationStatus: InvitationStatus.values.firstWhere(
        (e) => e.name == json['invitationStatus'],
        orElse: () => InvitationStatus.pending,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      revokedAt: json['revokedAt'] != null ? DateTime.parse(json['revokedAt'] as String) : null,
    );
  }
}
