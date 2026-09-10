import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sozotap/sos/domain/models/emergency_alert_model.dart';
import 'package:sozotap/sos/domain/repositories/emergency_alert_repository.dart';
import 'package:sozotap/sos/presentation/controllers/sos_controller.dart';
import 'package:sozotap/sos/presentation/controllers/sos_state.dart';

class FakeEmergencyAlertRepository implements EmergencyAlertRepository {
  final Map<String, EmergencyAlertModel> _alerts = {};

  @override
  Future<void> createAlert(EmergencyAlertModel alert) async {
    _alerts[alert.alertId] = alert;
  }

  @override
  Future<void> updateAlertStatus({
    required String alertId,
    required String status,
    DateTime? resolvedAt,
    String? failureReason,
  }) async {
    final existing = _alerts[alertId];
    if (existing != null) {
      _alerts[alertId] = existing.copyWith(
        status: status,
        resolvedAt: resolvedAt,
        failureReason: failureReason,
      );
    }
  }

  @override
  Stream<EmergencyAlertModel?> watchAlert(String alertId) {
    return Stream.value(_alerts[alertId]);
  }

  @override
  Future<EmergencyAlertModel?> getAlert(String alertId) async {
    return _alerts[alertId];
  }
}

void main() {
  group('SosController Unit Tests', () {
    late FakeEmergencyAlertRepository fakeRepository;
    late ProviderContainer container;

    setUp(() {
      fakeRepository = FakeEmergencyAlertRepository();
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('Initial state is idle with 5 seconds countdown', () {
      final controller = SosController(fakeRepository, container.listen(Provider((ref) => ref), (_, __) {}));
      expect(controller.debugState.countdownSeconds, 5);
      expect(controller.debugState.isCountingDown, false);
      expect(controller.debugState.isActivating, false);
      expect(controller.debugState.activeAlertId, null);
    });

    test('startCountdown sets isCountingDown true and initializes timer', () {
      final controller = SosController(fakeRepository, container.listen(Provider((ref) => ref), (_, __) {}));
      controller.startCountdown();

      expect(controller.debugState.isCountingDown, true);
      expect(controller.debugState.countdownSeconds, 5);
      controller.cancelCountdown();
    });

    test('cancelCountdown resets countdown state completely', () {
      final controller = SosController(fakeRepository, container.listen(Provider((ref) => ref), (_, __) {}));
      controller.startCountdown();
      controller.cancelCountdown();

      expect(controller.debugState.isCountingDown, false);
      expect(controller.debugState.countdownSeconds, 5);
      expect(controller.debugState.activeAlertId, null);
    });
  });
}
