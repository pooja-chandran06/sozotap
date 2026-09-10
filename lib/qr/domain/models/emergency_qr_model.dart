import 'package:cloud_firestore/cloud_firestore.dart';

class EmergencyQrModel {
  final String tokenId;
  final String ownerUserId;
  final String status; // 'active', 'revoked', 'expired'
  final DateTime createdAt;
  final DateTime? expiresAt;
  final DateTime? revokedAt;
  final DateTime? lastScannedAt;
  final int scanCount;
  final int allowedFieldsVersion;
  final int emergencyProfileVersion;
  final String displayEmergencyId; // e.g. ST-AB7K-92QP
  final bool notificationOnScan;
  final String? rawPayload; // Kept in memory only during creation display session

  const EmergencyQrModel({
    required this.tokenId,
    required this.ownerUserId,
    required this.status,
    required this.createdAt,
    this.expiresAt,
    this.revokedAt,
    this.lastScannedAt,
    required this.scanCount,
    required this.allowedFieldsVersion,
    required this.emergencyProfileVersion,
    required this.displayEmergencyId,
    required this.notificationOnScan,
    this.rawPayload,
  });

  bool get isActive => status == 'active' && (expiresAt == null || expiresAt!.isAfter(DateTime.now()));

  EmergencyQrModel copyWith({
    String? tokenId,
    String? ownerUserId,
    String? status,
    DateTime? createdAt,
    DateTime? expiresAt,
    DateTime? revokedAt,
    DateTime? lastScannedAt,
    int? scanCount,
    int? allowedFieldsVersion,
    int? emergencyProfileVersion,
    String? displayEmergencyId,
    bool? notificationOnScan,
    String? rawPayload,
  }) {
    return EmergencyQrModel(
      tokenId: tokenId ?? this.tokenId,
      ownerUserId: ownerUserId ?? this.ownerUserId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      revokedAt: revokedAt ?? this.revokedAt,
      lastScannedAt: lastScannedAt ?? this.lastScannedAt,
      scanCount: scanCount ?? this.scanCount,
      allowedFieldsVersion: allowedFieldsVersion ?? this.allowedFieldsVersion,
      emergencyProfileVersion: emergencyProfileVersion ?? this.emergencyProfileVersion,
      displayEmergencyId: displayEmergencyId ?? this.displayEmergencyId,
      notificationOnScan: notificationOnScan ?? this.notificationOnScan,
      rawPayload: rawPayload ?? this.rawPayload,
    );
  }

  factory EmergencyQrModel.fromFirestore(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>? ?? {};
    return EmergencyQrModel.fromMap(map, id: doc.id);
  }

  factory EmergencyQrModel.fromMap(Map<String, dynamic> map, {String? id}) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    DateTime? parseNullableDate(dynamic val) {
      if (val == null) return null;
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    return EmergencyQrModel(
      tokenId: id ?? (map['tokenId'] as String? ?? ''),
      ownerUserId: map['ownerUserId'] as String? ?? '',
      status: map['status'] as String? ?? 'active',
      createdAt: parseDate(map['createdAt']),
      expiresAt: parseNullableDate(map['expiresAt']),
      revokedAt: parseNullableDate(map['revokedAt']),
      lastScannedAt: parseNullableDate(map['lastScannedAt']),
      scanCount: (map['scanCount'] as num?)?.toInt() ?? 0,
      allowedFieldsVersion: (map['allowedFieldsVersion'] as num?)?.toInt() ?? 1,
      emergencyProfileVersion: (map['emergencyProfileVersion'] as num?)?.toInt() ?? 1,
      displayEmergencyId: map['displayEmergencyId'] as String? ?? 'ST-0000-0000',
      notificationOnScan: map['notificationOnScan'] as bool? ?? true,
    );
  }
}
