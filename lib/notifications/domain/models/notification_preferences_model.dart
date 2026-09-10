import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationPreferencesModel {
  final String userId;
  final bool sosAlertsEnabled;
  final bool medicationRemindersEnabled;
  final bool appointmentRemindersEnabled;
  final bool qrScanAlertsEnabled;
  final DateTime updatedAt;

  const NotificationPreferencesModel({
    required this.userId,
    required this.sosAlertsEnabled,
    required this.medicationRemindersEnabled,
    required this.appointmentRemindersEnabled,
    required this.qrScanAlertsEnabled,
    required this.updatedAt,
  });

  factory NotificationPreferencesModel.defaults(String userId) {
    return NotificationPreferencesModel(
      userId: userId,
      sosAlertsEnabled: true,
      medicationRemindersEnabled: true,
      appointmentRemindersEnabled: true,
      qrScanAlertsEnabled: true,
      updatedAt: DateTime.now(),
    );
  }

  NotificationPreferencesModel copyWith({
    String? userId,
    bool? sosAlertsEnabled,
    bool? medicationRemindersEnabled,
    bool? appointmentRemindersEnabled,
    bool? qrScanAlertsEnabled,
    DateTime? updatedAt,
  }) {
    return NotificationPreferencesModel(
      userId: userId ?? this.userId,
      sosAlertsEnabled: sosAlertsEnabled ?? this.sosAlertsEnabled,
      medicationRemindersEnabled: medicationRemindersEnabled ?? this.medicationRemindersEnabled,
      appointmentRemindersEnabled: appointmentRemindersEnabled ?? this.appointmentRemindersEnabled,
      qrScanAlertsEnabled: qrScanAlertsEnabled ?? this.qrScanAlertsEnabled,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'sosAlertsEnabled': sosAlertsEnabled,
      'medicationRemindersEnabled': medicationRemindersEnabled,
      'appointmentRemindersEnabled': appointmentRemindersEnabled,
      'qrScanAlertsEnabled': qrScanAlertsEnabled,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory NotificationPreferencesModel.fromFirestore(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>? ?? {};
    return NotificationPreferencesModel.fromMap(map, userId: doc.id);
  }

  factory NotificationPreferencesModel.fromMap(Map<String, dynamic> map, {required String userId}) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return NotificationPreferencesModel(
      userId: userId,
      sosAlertsEnabled: map['sosAlertsEnabled'] as bool? ?? true,
      medicationRemindersEnabled: map['medicationRemindersEnabled'] as bool? ?? true,
      appointmentRemindersEnabled: map['appointmentRemindersEnabled'] as bool? ?? true,
      qrScanAlertsEnabled: map['qrScanAlertsEnabled'] as bool? ?? true,
      updatedAt: parseDate(map['updatedAt']),
    );
  }
}
