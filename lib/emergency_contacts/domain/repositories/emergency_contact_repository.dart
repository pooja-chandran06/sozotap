import '../models/emergency_contact.dart';

abstract class EmergencyContactRepository {
  Future<List<EmergencyContact>> getContacts(String userId);
  Future<void> saveContact(EmergencyContact contact);
  Future<void> deleteContact(String userId, String contactId);
  Future<List<EmergencyContact>> getPriorityContacts(String userId, {int limit = 3});
}
