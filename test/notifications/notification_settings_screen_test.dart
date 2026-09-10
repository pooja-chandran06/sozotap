import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sozotap/notifications/presentation/screens/notification_settings_screen.dart';
import 'package:sozotap/notifications/presentation/providers/notification_providers.dart';
import 'package:sozotap/notifications/domain/models/notification_preferences_model.dart';

void main() {
  testWidgets('NotificationSettingsScreen renders all preference toggles', (WidgetTester tester) async {
    final mockPrefs = NotificationPreferencesModel.defaults('test_user');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notificationPreferencesProvider.overrideWithValue(AsyncValue.data(mockPrefs)),
        ],
        child: const MaterialApp(
          home: NotificationSettingsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Notification Settings'), findsOneWidget);
    expect(find.text('SOS Emergency Alerts'), findsOneWidget);
    expect(find.text('Medication Reminders'), findsOneWidget);
    expect(find.text('Appointment Reminders'), findsOneWidget);
    expect(find.text('QR Scan Activity Alerts'), findsOneWidget);
    expect(find.byType(SwitchListTile), findsNWidgets(4));
  });
}
