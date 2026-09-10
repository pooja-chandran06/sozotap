import 'package:sozotap/iot/models/iot_device_model.dart';
import 'package:sozotap/iot/models/device_event_model.dart';

abstract class IoTDeviceRepository {
  /// Stream list of paired devices for the current authenticated user
  Stream<List<IoTDevice>> watchUserDevices();

  /// Pair a new hardware device
  Future<void> pairDevice(IoTDevice device);

  /// Revoke an existing paired device
  Future<void> revokeDevice(String deviceId);

  /// Update device settings (display name, location flag, SOS flag)
  Future<void> updateDevice(IoTDevice device);

  /// Record an incoming device event (with duplicate prevention)
  Future<bool> recordDeviceEvent(DeviceEvent event);
}
