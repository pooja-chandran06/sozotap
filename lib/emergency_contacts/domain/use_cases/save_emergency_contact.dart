import '../models/emergency_contact.dart';
import '../repositories/emergency_contact_repository.dart';
import '../../../core/security/phone_normalizer.dart';

class SaveEmergencyContact {
  final EmergencyContactRepository _repository;
  final PhoneNormalizer _phoneNormalizer;

  SaveEmergencyContact(this._repository, this._phoneNormalizer);

  Future<void> execute(EmergencyContact contact) async {
    final normalizedPhone = _phoneNormalizer.normalize(contact.phoneNumber, contact.countryCode);
    final updatedContact = contact.copyWith(
      phoneNumber: normalizedPhone,
      updatedAt: DateTime.now(),
    );
    await _repository.saveContact(updatedContact);
  }
}
