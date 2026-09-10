import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sozotap/sos/presentation/screens/active_sos_screen.dart';
import 'package:sozotap/sos/presentation/providers/sos_providers.dart';
import 'package:sozotap/sos/domain/repositories/emergency_alert_repository.dart';
import 'package:sozotap/sos/domain/models/emergency_alert_model.dart';

class MockActiveAlertRepository implements EmergencyAlertRepository {
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
  Future<void> setLiveLocationEnabled({required String alertId, required bool enabled}) async {}

  @override
  Future<void> updateLiveLocation({
    required String alertId,
    required double latitude,
    required double longitude,
    required double accuracyMeters,
    required DateTime capturedAt,
  }) async {}

  @override
  Stream<EmergencyAlertModel?> watchAlert(String alertId) {
    return Stream.value(EmergencyAlertModel(
      alertId: alertId,
      ownerUserId: 'test_user',
      status: 'active',
      type: 'manual_sos',
      message: 'Active test alert',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      locationStatus: 'available',
      liveLocationEnabled: false,
      expiresAt: DateTime.now().add(const Duration(minutes: 30)),
      recipientContactIds: const [],
      notificationStatus: 'pending',
    ));
  }

  @override
  Future<EmergencyAlertModel?> getAlert(String alertId) async => null;
}

void main() {
  testWidgets('ActiveSosScreen renders live location switch and privacy notice', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          emergencyAlertRepositoryProvider.overrideWithValue(MockActiveAlertRepository()),
        ],
        child: const MaterialApp(
          home: ActiveSosScreen(alertId: 'test_alert_123'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Live Location Sharing'), findsOneWidget);
    expect(find.text('Privacy Notice: Live location sharing is active ONLY during this SOS session while the app is open in the foreground. Tracking stops automatically when SOS is resolved or after 30 minutes.'), findsOneWidget);
    expect(find.byType(Switch), findsOneWidget);
  });
}
