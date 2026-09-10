import 'package:cloud_firestore/cloud_firestore.dart';

class EmergencyAlertModel {
  final String alertId;
  final String ownerUserId;
  final String status; // 'countdown', 'active', 'cancelled', 'resolved', 'failed'
  final String type; // 'manual_sos'
  final String message;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? resolvedAt;
  final DateTime? lastLocationUpdateAt;
  final double? latitude;
  final double? longitude;
  final double? accuracyMeters;
  final DateTime? locationCapturedAt;
  final String locationStatus; // 'available', 'unavailable', 'permissionDenied', 'serviceDisabled'
  final bool liveLocationEnabled;
  final DateTime expiresAt;
  final List<String> recipientContactIds;
  final String notificationStatus; // 'pending'
  final String? failureReason;

  const EmergencyAlertModel({
    required this.alertId,
    required this.ownerUserId,
    required this.status,
    required this.type,
    required this.message,
    required this.createdAt,
    required this.updatedAt,
    this.resolvedAt,
    this.lastLocationUpdateAt,
    this.latitude,
    this.longitude,
    this.accuracyMeters,
    this.locationCapturedAt,
    required this.locationStatus,
    required this.liveLocationEnabled,
    required this.expiresAt,
    required this.recipientContactIds,
    required this.notificationStatus,
    this.failureReason,
  });

  EmergencyAlertModel copyWith({
    String? alertId,
    String? ownerUserId,
    String? status,
    String? type,
    String? message,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? resolvedAt,
    DateTime? lastLocationUpdateAt,
    double? latitude,
    double? longitude,
    double? accuracyMeters,
    DateTime? locationCapturedAt,
    String? locationStatus,
    bool? liveLocationEnabled,
    DateTime? expiresAt,
    List<String>? recipientContactIds,
    String? notificationStatus,
    String? failureReason,
  }) {
    return EmergencyAlertModel(
      alertId: alertId ?? this.alertId,
      ownerUserId: ownerUserId ?? this.ownerUserId,
      status: status ?? this.status,
      type: type ?? this.type,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      lastLocationUpdateAt: lastLocationUpdateAt ?? this.lastLocationUpdateAt,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      accuracyMeters: accuracyMeters ?? this.accuracyMeters,
      locationCapturedAt: locationCapturedAt ?? this.locationCapturedAt,
      locationStatus: locationStatus ?? this.locationStatus,
      liveLocationEnabled: liveLocationEnabled ?? this.liveLocationEnabled,
      expiresAt: expiresAt ?? this.expiresAt,
      recipientContactIds: recipientContactIds ?? this.recipientContactIds,
      notificationStatus: notificationStatus ?? this.notificationStatus,
      failureReason: failureReason ?? this.failureReason,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'alertId': alertId,
      'ownerUserId': ownerUserId,
      'status': status,
      'type': type,
      'message': message,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
      'lastLocationUpdateAt': lastLocationUpdateAt != null ? Timestamp.fromDate(lastLocationUpdateAt!) : null,
      'latitude': latitude,
      'longitude': longitude,
      'accuracyMeters': accuracyMeters,
      'locationCapturedAt': locationCapturedAt != null ? Timestamp.fromDate(locationCapturedAt!) : null,
      'locationStatus': locationStatus,
      'liveLocationEnabled': liveLocationEnabled,
      'expiresAt': Timestamp.fromDate(expiresAt),
      'recipientContactIds': recipientContactIds,
      'notificationStatus': notificationStatus,
      'failureReason': failureReason,
    };
  }

  factory EmergencyAlertModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return EmergencyAlertModel.fromMap(data, id: doc.id);
  }

  factory EmergencyAlertModel.fromMap(Map<String, dynamic> map, {String? id}) {
    DateTime parseDate(dynamic value, {DateTime? fallback}) {
      if (value is Timestamp) {
        return value.toDate();
      } else if (value is String) {
        return DateTime.tryParse(value) ?? (fallback ?? DateTime.now());
      } else if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      }
      return fallback ?? DateTime.now();
    }

    DateTime? parseNullableDate(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value);
      if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
      return null;
    }

    return EmergencyAlertModel(
      alertId: id ?? (map['alertId'] as String? ?? ''),
      ownerUserId: map['ownerUserId'] as String? ?? '',
      status: map['status'] as String? ?? 'active',
      type: map['type'] as String? ?? 'manual_sos',
      message: map['message'] as String? ?? '',
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
      resolvedAt: parseNullableDate(map['resolvedAt']),
      lastLocationUpdateAt: parseNullableDate(map['lastLocationUpdateAt']),
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      accuracyMeters: (map['accuracyMeters'] as num?)?.toDouble(),
      locationCapturedAt: parseNullableDate(map['locationCapturedAt']),
      locationStatus: map['locationStatus'] as String? ?? 'unavailable',
      liveLocationEnabled: map['liveLocationEnabled'] as bool? ?? false,
      expiresAt: parseDate(map['expiresAt'], fallback: DateTime.now().add(const Duration(hours: 24))),
      recipientContactIds: List<String>.from(map['recipientContactIds'] as List? ?? []),
      notificationStatus: map['notificationStatus'] as String? ?? 'pending',
      failureReason: map['failureReason'] as String?,
    );
  }
}
