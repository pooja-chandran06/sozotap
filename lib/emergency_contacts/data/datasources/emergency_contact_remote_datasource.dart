import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/emergency_contact_dto.dart';
import '../../../../utils/logger.dart';

class EmergencyContactRemoteDataSource {
  final FirebaseFirestore _firestore;

  EmergencyContactRemoteDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<List<EmergencyContactDto>> getContacts(String userId) async {
    try {
      // Primary: Query owner-isolated subcollection users/{userId}/emergency_contacts
      final userSubcollSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('emergency_contacts')
          .orderBy('priority', descending: false)
          .orderBy('createdAt', descending: true)
          .get();

      if (userSubcollSnapshot.docs.isNotEmpty) {
        return userSubcollSnapshot.docs
            .map((doc) => EmergencyContactDto.fromJson(doc.data()..['id'] = doc.id))
            .toList();
      }

      // Fallback: Query top-level collection emergency_contacts for backward compatibility
      final topLevelSnapshot = await _firestore
          .collection('emergency_contacts')
          .where('userId', isEqualTo: userId)
          .orderBy('priority', descending: false)
          .orderBy('createdAt', descending: true)
          .get();

      return topLevelSnapshot.docs
          .map((doc) => EmergencyContactDto.fromJson(doc.data()..['id'] = doc.id))
          .toList();
    } catch (e, st) {
      AppLogger.e('Failed to fetch emergency contacts', e, st);
      throw Exception('Failed to fetch emergency contacts.');
    }
  }

  Future<void> saveContact(EmergencyContactDto contact) async {
    try {
      final batch = _firestore.batch();

      // 1. Owner subcollection reference: users/{userId}/emergency_contacts/{contactId}
      final userContactRef = _firestore
          .collection('users')
          .doc(contact.userId)
          .collection('emergency_contacts')
          .doc(contact.id);

      // 2. Top-level reference: emergency_contacts/{contactId}
      final topLevelContactRef = _firestore.collection('emergency_contacts').doc(contact.id);

      // If saving a contact as primary, unset isPrimary on other user contacts
      if (contact.isPrimary) {
        final existingUserContacts = await _firestore
            .collection('users')
            .doc(contact.userId)
            .collection('emergency_contacts')
            .get();

        for (final doc in existingUserContacts.docs) {
          if (doc.id != contact.id) {
            batch.update(doc.ref, {'isPrimary': false});
            batch.update(_firestore.collection('emergency_contacts').doc(doc.id), {'isPrimary': false});
          }
        }
      }

      final data = contact.toJson();
      batch.set(userContactRef, data, SetOptions(merge: true));
      batch.set(topLevelContactRef, data, SetOptions(merge: true));

      await batch.commit();
    } catch (e, st) {
      AppLogger.e('Failed to save emergency contact', e, st);
      throw Exception('Failed to save emergency contact.');
    }
  }

  Future<void> deleteContact(String userId, String contactId) async {
    try {
      final batch = _firestore.batch();

      final userContactRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('emergency_contacts')
          .doc(contactId);

      final topLevelContactRef = _firestore.collection('emergency_contacts').doc(contactId);

      batch.delete(userContactRef);
      batch.delete(topLevelContactRef);

      await batch.commit();
    } catch (e, st) {
      AppLogger.e('Failed to delete emergency contact', e, st);
      throw Exception('Failed to delete emergency contact.');
    }
  }
}

