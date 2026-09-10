import '../models/emergency_alert_model.dart';

abstract class EmergencyAlertRepository {
  Future<void> createAlert(EmergencyAlertModel alert);
  Future<void> updateAlertStatus({
    required String alertId,
    required String status,
    DateTime? resolvedAt,
    String? failureReason,
  });
  Future<void> updateLiveLocation({
    required String alertId,
    required double latitude,
    required double longitude,
    required double accuracyMeters,
    required DateTime capturedAt,
  });
  Future<void> setLiveLocationEnabled({
    required String alertId,
    required bool enabled,
  });
  Stream<EmergencyAlertModel?> watchAlert(String alertId);
  Future<EmergencyAlertModel?> getAlert(String alertId);
}
