import 'package:flutter_test/flutter_test.dart';
import 'package:sozotap/caregiver/domain/models/caregiver_relationship_model.dart';

void main() {
  group('CaregiverRelationship Model Unit Tests', () {
    test('serializes and deserializes CaregiverRelationship correctly', () {
      final now = DateTime.now();
      final rel = CaregiverRelationship(
        relationshipId: 'rel_owner_cg',
        ownerUserId: 'owner_123',
        caregiverUserId: 'caregiver@example.com',
        permissions: const CaregiverPermissions(
          viewEmergencySummary: true,
          receiveSosAlerts: true,
          viewActiveSosLocation: true,
          manageEmergencyContacts: false,
        ),
        invitationStatus: InvitationStatus.pending,
        createdAt: now,
        updatedAt: now,
      );

      final json = rel.toJson();
      final restored = CaregiverRelationship.fromJson(json);

      expect(restored.relationshipId, 'rel_owner_cg');
      expect(restored.ownerUserId, 'owner_123');
      expect(restored.caregiverUserId, 'caregiver@example.com');
      expect(restored.permissions.viewEmergencySummary, true);
      expect(restored.permissions.manageEmergencyContacts, false);
      expect(restored.invitationStatus, InvitationStatus.pending);
    });
  });
}
