import 'package:flutter_test/flutter_test.dart';
import 'package:sozotap/core/security/phone_normalizer.dart';
import 'package:sozotap/emergency_contacts/data/models/emergency_contact_dto.dart';
import 'package:sozotap/emergency_contacts/domain/models/emergency_contact.dart';
import 'package:sozotap/emergency_contacts/domain/repositories/emergency_contact_repository.dart';
import 'package:sozotap/emergency_contacts/domain/use_cases/save_emergency_contact.dart';

class FakeEmergencyContactRepository implements EmergencyContactRepository {
  final List<EmergencyContact> savedContacts = [];

  @override
  Future<List<EmergencyContact>> getContacts(String userId) async {
    return savedContacts.where((c) => c.userId == userId).toList();
  }

  @override
  Future<void> saveContact(EmergencyContact contact) async {
    savedContacts.removeWhere((c) => c.id == contact.id);
    savedContacts.add(contact);
  }

  @override
  Future<void> deleteContact(String userId, String contactId) async {
    savedContacts.removeWhere((c) => c.userId == userId && c.id == contactId);
  }
}

void main() {
  group('Emergency Contact Domain & Use Case Tests', () {
    late PhoneNormalizer phoneNormalizer;
    late FakeEmergencyContactRepository fakeRepo;
    late SaveEmergencyContact saveUseCase;

    setUp(() {
      phoneNormalizer = PhoneNormalizer();
      fakeRepo = FakeEmergencyContactRepository();
      saveUseCase = SaveEmergencyContact(fakeRepo, phoneNormalizer);
    });

    test('Normalizes phone numbers cleanly', () {
      final normalized = phoneNormalizer.normalize('555-0199', '+1');
      expect(normalized, '+15550199');

      final e164 = phoneNormalizer.normalize('+447911123456');
      expect(e164, '+447911123456');
    });

    test('Throws error when name or phone is empty during save', () async {
      final invalidContact = EmergencyContact(
        id: 'c1',
        userId: 'u1',
        name: '',
        relationship: Relationship.family,
        phoneNumber: '5550199',
        priority: 1,
        canCall: true,
        canSms: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(() => saveUseCase.execute(invalidContact), throwsArgumentError);
    });

    test('SaveEmergencyContact successfully normalizes and saves primary contact', () async {
      final contact = EmergencyContact(
        id: 'c2',
        userId: 'u1',
        name: 'Jane Doe',
        relationship: Relationship.friend,
        phoneNumber: '555-0199',
        countryCode: '+1',
        priority: 2,
        isPrimary: true,
        canCall: true,
        canSms: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await saveUseCase.execute(contact);

      expect(fakeRepo.savedContacts.length, 1);
      final saved = fakeRepo.savedContacts.first;
      expect(saved.name, 'Jane Doe');
      expect(saved.phoneNumber, '+15550199');
      expect(saved.priority, 1); // Should be forced to 1 for primary contact
      expect(saved.isPrimary, true);
      expect(saved.contactId, 'c2');
      expect(saved.ownerUserId, 'u1');
    });

    test('EmergencyContactDto serialization and deserialization retains primary status', () {
      final contact = EmergencyContact(
        id: 'c3',
        userId: 'u2',
        name: 'Doctor Smith',
        relationship: Relationship.doctor,
        phoneNumber: '+15559999',
        priority: 1,
        isPrimary: true,
        canCall: true,
        canSms: false,
        createdAt: DateTime.parse('2026-01-01T00:00:00.000Z'),
        updatedAt: DateTime.parse('2026-01-01T00:00:00.000Z'),
      );

      final dto = EmergencyContactDto.fromDomain(contact);
      final json = dto.toJson();

      expect(json['contactId'], 'c3');
      expect(json['ownerUserId'], 'u2');
      expect(json['isPrimary'], true);

      final decodedDto = EmergencyContactDto.fromJson(json);
      final decodedDomain = decodedDto.toDomain();

      expect(decodedDomain.id, 'c3');
      expect(decodedDomain.name, 'Doctor Smith');
      expect(decodedDomain.isPrimary, true);
      expect(decodedDomain.priority, 1);
    });
  });
}
