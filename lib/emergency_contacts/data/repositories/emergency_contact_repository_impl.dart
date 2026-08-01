import '../../domain/models/emergency_contact.dart';
import '../../domain/repositories/emergency_contact_repository.dart';
import '../datasources/emergency_contact_remote_datasource.dart';
import '../models/emergency_contact_dto.dart';

class EmergencyContactRepositoryImpl implements EmergencyContactRepository {
  final EmergencyContactRemoteDataSource _remoteDataSource;

  EmergencyContactRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<EmergencyContact>> getContacts(String userId) async {
    final dtos = await _remoteDataSource.getContacts(userId);
    return dtos.map((dto) => dto.toDomain()).toList();
  }

  @override
  Future<List<EmergencyContact>> getPriorityContacts(String userId, {int limit = 3}) async {
    final contacts = await getContacts(userId);
    return contacts.take(limit).toList();
  }

  @override
  Future<void> saveContact(EmergencyContact contact) async {
    final dto = EmergencyContactDto.fromDomain(contact);
    await _remoteDataSource.saveContact(dto);
  }

  @override
  Future<void> deleteContact(String userId, String contactId) async {
    await _remoteDataSource.deleteContact(userId, contactId);
  }
}
