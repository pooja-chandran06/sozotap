import 'package:cloud_firestore/cloud_firestore.dart';

class DeviceTokenModel {
  final String tokenId;
  final String token;
  final String platform; // 'android', 'ios', 'web'
  final String appVersion;
  final String deviceIdHash; // SHA-256 hash of device ID
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime lastSeenAt;
  final bool enabled;
  final String notificationPermissionStatus; // 'granted', 'denied', 'notDetermined'

  const DeviceTokenModel({
    required this.tokenId,
    required this.token,
    required this.platform,
    required this.appVersion,
    required this.deviceIdHash,
    required this.createdAt,
    required this.updatedAt,
    required this.lastSeenAt,
    required this.enabled,
    required this.notificationPermissionStatus,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'tokenId': tokenId,
      'token': token,
      'platform': platform,
      'appVersion': appVersion,
      'deviceIdHash': deviceIdHash,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'lastSeenAt': Timestamp.fromDate(lastSeenAt),
      'enabled': enabled,
      'notificationPermissionStatus': notificationPermissionStatus,
    };
  }

  factory DeviceTokenModel.fromFirestore(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>? ?? {};
    return DeviceTokenModel.fromMap(map, id: doc.id);
  }

  factory DeviceTokenModel.fromMap(Map<String, dynamic> map, {String? id}) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return DeviceTokenModel(
      tokenId: id ?? (map['tokenId'] as String? ?? ''),
      token: map['token'] as String? ?? '',
      platform: map['platform'] as String? ?? 'unknown',
      appVersion: map['appVersion'] as String? ?? '1.0.0',
      deviceIdHash: map['deviceIdHash'] as String? ?? '',
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
      lastSeenAt: parseDate(map['lastSeenAt']),
      enabled: map['enabled'] as bool? ?? true,
      notificationPermissionStatus: map['notificationPermissionStatus'] as String? ?? 'notDetermined',
    );
  }
}
