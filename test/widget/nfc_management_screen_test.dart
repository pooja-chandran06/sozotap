import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sozotap/nfc/presentation/screens/nfc_management_screen.dart';
import 'package:sozotap/nfc/domain/repositories/nfc_tag_repository.dart';

class MockNfcTagRepository implements NfcTagRepository {
  @override
  Future<bool> isNfcAvailable() async => true;

  @override
  Future<void> writeEmergencyTokenTag(String opaqueToken) async {}

  @override
  Future<String?> readEmergencyTokenTag() async => 'sozo_live_sample';

  @override
  Future<void> stopSession() async {}
}

void main() {
  testWidgets('NfcManagementScreen renders hardware status, action buttons, and QR fallback notice', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          nfcRepositoryProvider.overrideWithValue(MockNfcTagRepository()),
        ],
        child: const MaterialApp(
          home: NfcManagementScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('NFC SmartTag Manager'), findsOneWidget);
    expect(find.text('NFC Hardware Available'), findsOneWidget);
    expect(find.text('Program SOZOTAP NFC Tag'), findsOneWidget);
    expect(find.text('Scan & Validate NFC Tag'), findsOneWidget);
    expect(find.textContaining('Use the QR medical ID if NFC is unavailable'), findsWidgets);
  });
}
