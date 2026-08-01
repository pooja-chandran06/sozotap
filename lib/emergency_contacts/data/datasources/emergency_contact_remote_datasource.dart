import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/emergency_contact_dto.dart';
import '../../../../utils/logger.dart';

class EmergencyContactRemoteDataSource {
  final FirebaseFirestore _firestore;

  EmergencyContactRemoteDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<List<EmergencyContactDto>> getContacts(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('emergency_contacts')
          .where('userId', isEqualTo: userId)
          .orderBy('priority', descending: false)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => EmergencyContactDto.fromJson(doc.data()..['id'] = doc.id))
          .toList();
    } catch (e, st) {
      AppLogger.e('Failed to fetch emergency contacts', e, st);
      throw Exception('Failed to fetch emergency contacts.');
    }
  }

  Future<void> saveContact(EmergencyContactDto contact) async {
    try {
      await _firestore
          .collection('emergency_contacts')
          .doc(contact.id)
          .set(contact.toJson(), SetOptions(merge: true));
    } catch (e, st) {
      AppLogger.e('Failed to save emergency contact', e, st);
      throw Exception('Failed to save emergency contact.');
    }
  }

  Future<void> deleteContact(String userId, String contactId) async {
    try {
      await _firestore
          .collection('emergency_contacts')
          .doc(contactId)
          .delete();
    } catch (e, st) {
      AppLogger.e('Failed to delete emergency contact', e, st);
      throw Exception('Failed to delete emergency contact.');
    }
  }
}
