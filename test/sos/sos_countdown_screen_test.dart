import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sozotap/sos/presentation/screens/sos_countdown_screen.dart';
import 'package:sozotap/sos/presentation/providers/sos_providers.dart';
import 'package:sozotap/sos/domain/repositories/emergency_alert_repository.dart';
import 'package:sozotap/sos/domain/models/emergency_alert_model.dart';

class MockEmergencyAlertRepository implements EmergencyAlertRepository {
  @override
  Future<void> createAlert(EmergencyAlertModel alert) async {}

  @override
  Future<void> updateAlertStatus({
    required String alertId,
    required String status,
    DateTime? resolvedAt,
    String? failureReason,
  }) async {}

  @override
  Future<void> updateLiveLocation({
    required String alertId,
    required double latitude,
    required double longitude,
    required double accuracyMeters,
    required DateTime capturedAt,
  }) async {}

  @override
  Future<void> setLiveLocationEnabled({
    required String alertId,
    required bool enabled,
  }) async {}

  @override
  Stream<EmergencyAlertModel?> watchAlert(String alertId) => Stream.value(null);

  @override
  Future<EmergencyAlertModel?> getAlert(String alertId) async => null;
}

void main() {
  testWidgets('SosCountdownScreen renders countdown text and CANCEL SOS button', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          emergencyAlertRepositoryProvider.overrideWithValue(MockEmergencyAlertRepository()),
        ],
        child: const MaterialApp(
          home: SosCountdownScreen(),
        ),
      ),
    );

    await tester.pump();

    // Verify UI components render properly
    expect(find.text('EMERGENCY SOS INITIATED'), findsOneWidget);
    expect(find.text('CANCEL SOS'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Tap Cancel SOS button
    await tester.tap(find.text('CANCEL SOS'));
    await tester.pump();
  });
}
