import '../models/emergency_contact.dart';
import '../repositories/emergency_contact_repository.dart';

class GetEmergencyContacts {
  final EmergencyContactRepository _repository;

  GetEmergencyContacts(this._repository);

  Future<List<EmergencyContact>> execute(String userId) {
    return _repository.getContacts(userId);
  }
}
