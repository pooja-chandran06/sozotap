import '../repositories/emergency_contact_repository.dart';

class DeleteEmergencyContact {
  final EmergencyContactRepository _repository;

  DeleteEmergencyContact(this._repository);

  Future<void> execute(String userId, String contactId) async {
    await _repository.deleteContact(userId, contactId);
  }
}
