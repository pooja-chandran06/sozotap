import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationPreference {
  final bool sosPushEnabled;
  final bool sosSmsEnabled;
  final bool medicationReminderEnabled;
  final bool appointmentReminderEnabled;
  final bool qrScanAlertEnabled;
  final DateTime updatedAt;

  NotificationPreference({
    this.sosPushEnabled = true,
    this.sosSmsEnabled = true,
    this.medicationReminderEnabled = true,
    this.appointmentReminderEnabled = true,
    this.qrScanAlertEnabled = true,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'sosPushEnabled': sosPushEnabled,
      'sosSmsEnabled': sosSmsEnabled,
      'medicationReminderEnabled': medicationReminderEnabled,
      'appointmentReminderEnabled': appointmentReminderEnabled,
      'qrScanAlertEnabled': qrScanAlertEnabled,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory NotificationPreference.fromMap(Map<String, dynamic>? map) {
    if (map == null) return NotificationPreference();
    return NotificationPreference(
      sosPushEnabled: map['sosPushEnabled'] ?? true,
      sosSmsEnabled: map['sosSmsEnabled'] ?? true,
      medicationReminderEnabled: map['medicationReminderEnabled'] ?? true,
      appointmentReminderEnabled: map['appointmentReminderEnabled'] ?? true,
      qrScanAlertEnabled: map['qrScanAlertEnabled'] ?? true,
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  NotificationPreference copyWith({
    bool? sosPushEnabled,
    bool? sosSmsEnabled,
    bool? medicationReminderEnabled,
    bool? appointmentReminderEnabled,
    bool? qrScanAlertEnabled,
    DateTime? updatedAt,
  }) {
    return NotificationPreference(
      sosPushEnabled: sosPushEnabled ?? this.sosPushEnabled,
      sosSmsEnabled: sosSmsEnabled ?? this.sosSmsEnabled,
      medicationReminderEnabled: medicationReminderEnabled ?? this.medicationReminderEnabled,
      appointmentReminderEnabled: appointmentReminderEnabled ?? this.appointmentReminderEnabled,
      qrScanAlertEnabled: qrScanAlertEnabled ?? this.qrScanAlertEnabled,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
