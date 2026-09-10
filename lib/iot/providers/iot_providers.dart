import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sozotap/iot/models/iot_device_model.dart';
import 'package:sozotap/iot/domain/repositories/iot_device_repository.dart';
import 'package:sozotap/iot/data/repositories/iot_device_repository_impl.dart';

final ioTDeviceRepositoryProvider = Provider<IoTDeviceRepository>((ref) {
  return IoTDeviceRepositoryImpl();
});

final userDevicesStreamProvider = StreamProvider<List<IoTDevice>>((ref) {
  final repo = ref.watch(ioTDeviceRepositoryProvider);
  return repo.watchUserDevices();
});
