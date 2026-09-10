import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sozotap/iot/presentation/screens/device_management_screen.dart';
import 'package:sozotap/iot/providers/iot_providers.dart';
import 'package:sozotap/iot/models/iot_device_model.dart';
import 'package:sozotap/iot/domain/repositories/iot_device_repository.dart';

class MockIoTDeviceRepository implements IoTDeviceRepository {
  @override
  Stream<List<IoTDevice>> watchUserDevices() => Stream.value([]);

  @override
  Future<void> pairDevice(IoTDevice device) async {}

  @override
  Future<void> revokeDevice(String deviceId) async {}

  @override
  Future<void> updateDevice(IoTDevice device) async {}

  @override
  Future<bool> recordDeviceEvent(dynamic event) async => true;
}

void main() {
  testWidgets('DeviceManagementScreen renders empty state when no devices paired', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userDevicesStreamProvider.overrideWith((ref) => Stream.value([])),
          ioTDeviceRepositoryProvider.overrideWithValue(MockIoTDeviceRepository()),
        ],
        child: const MaterialApp(
          home: DeviceManagementScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Paired Emergency Devices'), findsOneWidget);
    expect(find.text('No Devices Paired Yet'), findsOneWidget);
    expect(find.text('Pair New Device'), findsOneWidget);
  });
}
