import '../models/emergency_contact.dart';
import '../repositories/emergency_contact_repository.dart';
import '../../../core/security/phone_normalizer.dart';

class SaveEmergencyContact {
  final EmergencyContactRepository _repository;
  final PhoneNormalizer _phoneNormalizer;

  SaveEmergencyContact(this._repository, this._phoneNormalizer);

  Future<void> execute(EmergencyContact contact) async {
    if (contact.name.trim().isEmpty) {
      throw ArgumentError('Contact name is required.');
    }
    if (contact.phoneNumber.trim().isEmpty) {
      throw ArgumentError('Phone number is required.');
    }

    final normalizedPhone = _phoneNormalizer.normalize(contact.phoneNumber, contact.countryCode);
    final cleaned = normalizedPhone.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleaned.length < 7) {
      throw ArgumentError('Please enter a valid phone number (minimum 7 digits).');
    }

    final updatedContact = contact.copyWith(
      phoneNumber: normalizedPhone,
      priority: contact.isPrimary ? 1 : contact.priority,
      updatedAt: DateTime.now(),
    );
    await _repository.saveContact(updatedContact);
  }
}

