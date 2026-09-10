import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sozotap/sos/domain/models/emergency_alert_model.dart';
import 'package:sozotap/sos/domain/repositories/emergency_alert_repository.dart';
import 'package:sozotap/sos/presentation/controllers/sos_controller.dart';

class MockLiveAlertRepository implements EmergencyAlertRepository {
  bool isLiveEnabled = false;

  @override
  Future<void> createAlert(EmergencyAlertModel alert) async {}

  @override
  Future<void> updateAlertStatus({
    required String alertId,
    required String status,
    DateTime? resolvedAt,
    String? failureReason,
  }) async {
    if (status == 'resolved') {
      isLiveEnabled = false;
    }
  }

  @override
  Future<void> setLiveLocationEnabled({
    required String alertId,
    required bool enabled,
  }) async {
    isLiveEnabled = enabled;
  }

  @override
  Future<void> updateLiveLocation({
    required String alertId,
    required double latitude,
    required double longitude,
    required double accuracyMeters,
    required DateTime capturedAt,
  }) async {}

  @override
  Stream<EmergencyAlertModel?> watchAlert(String alertId) => Stream.value(null);

  @override
  Future<EmergencyAlertModel?> getAlert(String alertId) async => null;
}

void main() {
  group('Live Location Controller Lifecycle Tests', () {
    late MockLiveAlertRepository mockRepo;
    late ProviderContainer container;

    setUp(() {
      mockRepo = MockLiveAlertRepository();
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('stopLiveLocationTracking updates state and calls repository to disable tracking', () async {
      final controller = SosController(mockRepo, container.listen(Provider((ref) => ref), (_, __) {}));
      
      await controller.stopLiveLocationTracking('test_alert_id');

      expect(controller.debugState.isLiveLocationActive, isFalse);
      expect(mockRepo.isLiveEnabled, isFalse);
    });
  });
}
