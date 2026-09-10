import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sozotap/settings/presentation/screens/settings_screen.dart';
import 'package:sozotap/settings/presentation/providers/settings_providers.dart';
import 'package:sozotap/settings/data/repositories/settings_repository.dart';
import 'package:sozotap/core/offline/hive_cache_service.dart';

class MockSettingsRepository implements SettingsRepository {
  @override
  DateTime? getLastSyncedAt() => DateTime(2026, 9, 10, 10, 0);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockHiveCacheService implements HiveCacheService {
  @override
  Future<void> clearUserCache(String uid) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('SettingsScreen displays theme, privacy, and system sections', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(MockSettingsRepository()),
          hiveCacheServiceProvider.overrideWithValue(MockHiveCacheService()),
        ],
        child: const MaterialApp(
          home: SettingsScreen(),
        ),
      ),
    );

    expect(find.text('SOZOTAP Settings'), findsOneWidget);
    expect(find.text('APPEARANCE & THEME'), findsOneWidget);
    expect(find.text('PRIVACY & SECURITY'), findsOneWidget);
    expect(find.text('SYSTEM & LEGAL'), findsOneWidget);
    expect(find.text('Sign Out'), findsOneWidget);
  });
}
