import 'dart:io';
import '../../domain/models/medical_profile.dart';
import '../../domain/repositories/medical_profile_repository.dart';
import '../datasources/medical_profile_remote_datasource.dart';
import '../models/medical_profile_dto.dart';

class MedicalProfileRepositoryImpl implements MedicalProfileRepository {
  final MedicalProfileRemoteDatasource _remoteDatasource;

  MedicalProfileRepositoryImpl(this._remoteDatasource);

  @override
  Future<MedicalProfile?> getProfile(String uid) async {
    final dto = await _remoteDatasource.getProfile(uid);
    return dto?.toDomain();
  }

  @override
  Future<void> saveProfile(MedicalProfile profile) async {
    final dto = MedicalProfileDto.fromDomain(profile);
    await _remoteDatasource.saveProfile(dto);
  }

  @override
  Future<String?> uploadProfilePhoto(String uid, File imageFile) async {
    return await _remoteDatasource.uploadProfilePhoto(uid, imageFile);
  }
}
