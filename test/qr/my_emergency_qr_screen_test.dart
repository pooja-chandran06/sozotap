import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sozotap/qr/presentation/screens/my_emergency_qr_screen.dart';
import 'package:sozotap/qr/presentation/providers/qr_providers.dart';
import 'package:sozotap/qr/domain/repositories/emergency_qr_repository.dart';
import 'package:sozotap/qr/domain/models/emergency_qr_model.dart';
import 'package:qr_flutter/qr_flutter.dart';

class MockEmergencyQrRepository implements EmergencyQrRepository {
  @override
  Future<Map<String, dynamic>> createEmergencyQr() async => {
        'tokenId': 'qr_123',
        'rawPayload': 'https://sozotap.com/qr/sample_opaque_token',
        'displayEmergencyId': 'ST-AB7K-92QP',
        'expiresAt': DateTime.now().add(const Duration(days: 90)).toIso8601String(),
      };

  @override
  Future<void> revokeEmergencyQr(String tokenId) async {}

  @override
  Future<Map<String, dynamic>> regenerateEmergencyQr() async => {
        'tokenId': 'qr_456',
        'rawPayload': 'https://sozotap.com/qr/sample_new_token',
        'displayEmergencyId': 'ST-XY89-0012',
        'expiresAt': DateTime.now().add(const Duration(days: 90)).toIso8601String(),
      };

  @override
  Future<EmergencyQrModel?> getActiveQrMetadata() async => EmergencyQrModel(
        tokenId: 'qr_123',
        ownerUserId: 'user_456',
        status: 'active',
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 90)),
        scanCount: 0,
        allowedFieldsVersion: 1,
        emergencyProfileVersion: 1,
        displayEmergencyId: 'ST-AB7K-92QP',
        notificationOnScan: true,
      );

  @override
  Stream<EmergencyQrModel?> watchActiveQrMetadata() {
    return Stream.value(EmergencyQrModel(
      tokenId: 'qr_123',
      ownerUserId: 'user_456',
      status: 'active',
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(days: 90)),
      scanCount: 0,
      allowedFieldsVersion: 1,
      emergencyProfileVersion: 1,
      displayEmergencyId: 'ST-AB7K-92QP',
      notificationOnScan: true,
    ));
  }
}

void main() {
  testWidgets('MyEmergencyQrScreen renders QrImageView and backup Emergency ID', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          emergencyQrRepositoryProvider.overrideWithValue(MockEmergencyQrRepository()),
        ],
        child: const MaterialApp(
          home: MyEmergencyQrScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('My Emergency QR'), findsOneWidget);
    expect(find.text('ST-AB7K-92QP'), findsOneWidget);
    expect(find.text('SECURITY NOTICE: This QR code contains no medical details in plaintext. It is a cryptographically secure access key. Replace or revoke it if lost or copied.'), findsOneWidget);
    expect(find.byType(QrImageView), findsOneWidget);
    expect(find.text('SHARE QR'), findsOneWidget);
  });
}
