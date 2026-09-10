import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sozotap/core/logging/safe_logger.dart';
import 'package:sozotap/core/errors/app_exception.dart';
import 'package:sozotap/iot/models/iot_device_model.dart';
import 'package:sozotap/iot/models/device_event_model.dart';
import 'package:sozotap/iot/domain/repositories/iot_device_repository.dart';

class IoTDeviceRepositoryImpl implements IoTDeviceRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final Set<String> _processedIdempotencyKeys = {};

  IoTDeviceRepositoryImpl({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  String get _currentUid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw const AuthException('User must be authenticated.');
    return uid;
  }

  @override
  Stream<List<IoTDevice>> watchUserDevices() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value([]);

    return _firestore
        .collection('iot_devices')
        .where('ownerUserId', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => IoTDevice.fromJson(doc.data()))
          .where((dev) => dev.status != DeviceStatus.revoked)
          .toList();
    });
  }

  @override
  Future<void> pairDevice(IoTDevice device) async {
    try {
      final uid = _currentUid;
      final docRef = _firestore.collection('iot_devices').doc(device.deviceId);
      await docRef.set(device.copyWith(displayName: device.displayName).toJson());
      SafeLogger.info('IoT Device ${device.deviceId} paired for user $uid');
    } catch (e) {
      SafeLogger.error('Failed to pair IoT device: $e');
      throw ServerException('Failed to pair device: $e');
    }
  }

  @override
  Future<void> revokeDevice(String deviceId) async {
    try {
      final docRef = _firestore.collection('iot_devices').doc(deviceId);
      await docRef.update({
        'status': DeviceStatus.revoked.name,
        'revokedAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      });
      SafeLogger.info('IoT Device $deviceId revoked successfully');
    } catch (e) {
      SafeLogger.error('Failed to revoke IoT device: $e');
      throw ServerException('Failed to revoke device: $e');
    }
  }

  @override
  Future<void> updateDevice(IoTDevice device) async {
    try {
      final docRef = _firestore.collection('iot_devices').doc(device.deviceId);
      await docRef.update(device.toJson());
    } catch (e) {
      SafeLogger.error('Failed to update IoT device: $e');
      throw ServerException('Failed to update device: $e');
    }
  }

  @override
  Future<bool> recordDeviceEvent(DeviceEvent event) async {
    // Duplicate prevention check
    if (_processedIdempotencyKeys.contains(event.idempotencyKey)) {
      SafeLogger.warn('Duplicate IoT event ignored with idempotencyKey ${event.idempotencyKey}');
      return false;
    }

    try {
      final docRef = _firestore.collection('device_events').doc(event.eventId);
      await docRef.set(event.toJson());
      _processedIdempotencyKeys.add(event.idempotencyKey);
      SafeLogger.info('Device event ${event.eventId} recorded successfully');
      return true;
    } catch (e) {
      SafeLogger.error('Failed to record device event: $e');
      return false;
    }
  }
}
