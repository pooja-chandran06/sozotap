import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sozotap/settings/presentation/screens/privacy_settings_screen.dart';
import 'package:sozotap/settings/presentation/providers/settings_providers.dart';
import 'package:sozotap/settings/domain/models/privacy_settings_model.dart';
import 'package:sozotap/settings/data/repositories/settings_repository.dart';

class MockSettingsRepository implements SettingsRepository {
  @override
  Future<void> updatePrivacySettings(PrivacySettingsModel settings) async {}

  @override
  Future<void> resetPrivacyToRecommended() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('PrivacySettingsScreen renders master switch and privacy consent flags', (WidgetTester tester) async {
    final mockSettings = PrivacySettingsModel(
      emergencyAccessEnabled: true,
      shareNameInEmergency: true,
      shareBloodGroupInEmergency: true,
      shareAllergiesInEmergency: true,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          privacySettingsStreamProvider.overrideWith((ref) => Stream.value(mockSettings)),
          settingsRepositoryProvider.overrideWithValue(MockSettingsRepository()),
        ],
        child: const MaterialApp(
          home: PrivacySettingsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Privacy & Emergency Sharing'), findsOneWidget);
    expect(find.text('Master Emergency Access'), findsOneWidget);
    expect(find.text('Share Full Name'), findsOneWidget);
    expect(find.text('Share Blood Group'), findsOneWidget);
    expect(find.text('Share Critical Allergies'), findsOneWidget);
  });
}
