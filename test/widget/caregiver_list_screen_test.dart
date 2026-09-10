import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sozotap/caregiver/presentation/screens/caregiver_list_screen.dart';
import 'package:sozotap/caregiver/providers/caregiver_providers.dart';
import 'package:sozotap/caregiver/domain/repositories/caregiver_repository.dart';

class MockCaregiverRepository implements CaregiverRepository {
  @override
  Stream<List<dynamic>> watchCaregivers() => Stream.value([]);

  @override
  Future<void> inviteCaregiver(String email, dynamic permissions) async {}

  @override
  Future<void> acceptInvitation(String relationshipId) async {}

  @override
  Future<void> declineInvitation(String relationshipId) async {}

  @override
  Future<void> revokeCaregiver(String relationshipId) async {}
}

void main() {
  testWidgets('CaregiverListScreen renders empty state when no caregivers invited', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          caregiversStreamProvider.overrideWith((ref) => Stream.value([])),
          caregiverRepositoryProvider.overrideWithValue(MockCaregiverRepository()),
        ],
        child: const MaterialApp(
          home: CaregiverListScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Caregiver Access & Grants'), findsOneWidget);
    expect(find.text('No Caregivers Invited'), findsOneWidget);
    expect(find.text('Invite Caregiver'), findsOneWidget);
  });
}
