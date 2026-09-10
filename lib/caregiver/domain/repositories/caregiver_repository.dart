import 'package:sozotap/caregiver/domain/models/caregiver_relationship_model.dart';

abstract class CaregiverRepository {
  /// Stream caregiver relationships where the user is either owner or caregiver
  Stream<List<CaregiverRelationship>> watchCaregivers();

  /// Invite a registered user as a caregiver by email
  Future<void> inviteCaregiver(String email, CaregiverPermissions permissions);

  /// Accept an incoming caregiver invitation
  Future<void> acceptInvitation(String relationshipId);

  /// Decline an incoming caregiver invitation
  Future<void> declineInvitation(String relationshipId);

  /// Revoke an existing caregiver relationship
  Future<void> revokeCaregiver(String relationshipId);
}
