import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import '../../domain/models/emergency_alert_model.dart';
import '../../domain/repositories/emergency_alert_repository.dart';

class FirebaseEmergencyAlertRepository implements EmergencyAlertRepository {
  final FirebaseFirestore _firestore;
  final Logger _logger = Logger();

  FirebaseEmergencyAlertRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<void> createAlert(EmergencyAlertModel alert) async {
    try {
      if (kDebugMode) {
        _logger.i('Creating emergency_alerts/${alert.alertId}');
      }
      await _firestore
          .collection('emergency_alerts')
          .doc(alert.alertId)
          .set(alert.toFirestore());
    } catch (e, stackTrace) {
      _logger.e('Failed to create Firestore alert ${alert.alertId}', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> updateAlertStatus({
    required String alertId,
    required String status,
    DateTime? resolvedAt,
    String? failureReason,
  }) async {
    try {
      if (kDebugMode) {
        _logger.i('Updating status of emergency_alerts/$alertId to $status');
      }
      final updates = <String, dynamic>{
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (status == 'resolved') {
        updates['liveLocationEnabled'] = false;
      }

      if (resolvedAt != null) {
        updates['resolvedAt'] = Timestamp.fromDate(resolvedAt);
      } else if (status == 'resolved') {
        updates['resolvedAt'] = FieldValue.serverTimestamp();
      }

      if (failureReason != null) {
        updates['failureReason'] = failureReason;
      }

      await _firestore
          .collection('emergency_alerts')
          .doc(alertId)
          .update(updates);
    } catch (e, stackTrace) {
      _logger.e('Failed to update status for alert $alertId', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> updateLiveLocation({
    required String alertId,
    required double latitude,
    required double longitude,
    required double accuracyMeters,
    required DateTime capturedAt,
  }) async {
    try {
      // In production release logs, do not log raw lat/lng
      if (kDebugMode) {
        _logger.d('Updating live location for alert $alertId: ($latitude, $longitude)');
      } else {
        _logger.i('Updating live location coordinates for alert $alertId');
      }

      await _firestore.collection('emergency_alerts').doc(alertId).update({
        'latitude': latitude,
        'longitude': longitude,
        'accuracyMeters': accuracyMeters,
        'locationCapturedAt': Timestamp.fromDate(capturedAt),
        'lastLocationUpdateAt': FieldValue.serverTimestamp(),
        'locationStatus': 'available',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e, stackTrace) {
      _logger.e('Failed to update live location for alert $alertId', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> setLiveLocationEnabled({
    required String alertId,
    required bool enabled,
  }) async {
    try {
      if (kDebugMode) {
        _logger.i('Setting liveLocationEnabled=$enabled for alert $alertId');
      }
      await _firestore.collection('emergency_alerts').doc(alertId).update({
        'liveLocationEnabled': enabled,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e, stackTrace) {
      _logger.e('Failed to toggle live location for alert $alertId', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Stream<EmergencyAlertModel?> watchAlert(String alertId) {
    return _firestore
        .collection('emergency_alerts')
        .doc(alertId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return null;
      }
      return EmergencyAlertModel.fromFirestore(snapshot);
    });
  }

  @override
  Future<EmergencyAlertModel?> getAlert(String alertId) async {
    try {
      final doc = await _firestore.collection('emergency_alerts').doc(alertId).get();
      if (!doc.exists || doc.data() == null) return null;
      return EmergencyAlertModel.fromFirestore(doc);
    } catch (e, stackTrace) {
      _logger.e('Failed to get alert $alertId', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
}
