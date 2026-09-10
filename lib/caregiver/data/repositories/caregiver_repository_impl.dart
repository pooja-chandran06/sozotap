import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sozotap/core/logging/safe_logger.dart';
import 'package:sozotap/core/errors/app_exception.dart';
import 'package:sozotap/caregiver/domain/models/caregiver_relationship_model.dart';
import 'package:sozotap/caregiver/domain/repositories/caregiver_repository.dart';

class CaregiverRepositoryImpl implements CaregiverRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CaregiverRepositoryImpl({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  @override
  Stream<List<CaregiverRelationship>> watchCaregivers() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value([]);

    return _firestore
        .collection('caregiver_relationships')
        .where('ownerUserId', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => CaregiverRelationship.fromJson(doc.data()))
          .where((rel) => rel.invitationStatus != InvitationStatus.revoked)
          .toList();
    });
  }

  @override
  Future<void> inviteCaregiver(String email, CaregiverPermissions permissions) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw const AuthException('User must be authenticated.');

    try {
      final relId = 'rel_${uid}_${email.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}';
      final rel = CaregiverRelationship(
        relationshipId: relId,
        ownerUserId: uid,
        caregiverUserId: email.trim(),
        permissions: permissions,
        invitationStatus: InvitationStatus.pending,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore.collection('caregiver_relationships').doc(relId).set(rel.toJson());
      SafeLogger.info('Caregiver invitation sent to $email');
    } catch (e) {
      SafeLogger.error('Failed to invite caregiver: $e');
      throw ServerException('Failed to invite caregiver: $e');
    }
  }

  @override
  Future<void> acceptInvitation(String relationshipId) async {
    try {
      await _firestore.collection('caregiver_relationships').doc(relationshipId).update({
        'invitationStatus': InvitationStatus.accepted.name,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw ServerException('Failed to accept invitation: $e');
    }
  }

  @override
  Future<void> declineInvitation(String relationshipId) async {
    try {
      await _firestore.collection('caregiver_relationships').doc(relationshipId).update({
        'invitationStatus': InvitationStatus.declined.name,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw ServerException('Failed to decline invitation: $e');
    }
  }

  @override
  Future<void> revokeCaregiver(String relationshipId) async {
    try {
      await _firestore.collection('caregiver_relationships').doc(relationshipId).update({
        'invitationStatus': InvitationStatus.revoked.name,
        'revokedAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw ServerException('Failed to revoke caregiver: $e');
    }
  }
}
