import 'package:cloud_firestore/cloud_firestore.dart';

class DeviceToken {
  final String tokenId;
  final String ownerUserId;
  final String token;
  final String platform;
  final String? appVersion;
  final String? notificationPermissionStatus;
  final bool enabled;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime lastSeenAt;

  DeviceToken({
    required this.tokenId,
    required this.ownerUserId,
    required this.token,
    required this.platform,
    this.appVersion,
    this.notificationPermissionStatus,
    required this.enabled,
    required this.createdAt,
    required this.updatedAt,
    required this.lastSeenAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'tokenId': tokenId,
      'ownerUserId': ownerUserId,
      'token': token,
      'platform': platform,
      'appVersion': appVersion,
      'notificationPermissionStatus': notificationPermissionStatus,
      'enabled': enabled,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'lastSeenAt': Timestamp.fromDate(lastSeenAt),
    };
  }

  factory DeviceToken.fromMap(Map<String, dynamic> map, String id) {
    return DeviceToken(
      tokenId: id,
      ownerUserId: map['ownerUserId'] ?? '',
      token: map['token'] ?? '',
      platform: map['platform'] ?? 'unknown',
      appVersion: map['appVersion'],
      notificationPermissionStatus: map['notificationPermissionStatus'],
      enabled: map['enabled'] ?? true,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastSeenAt: (map['lastSeenAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
