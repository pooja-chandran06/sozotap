import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../../providers/shared_preferences_provider.dart';
import '../../data/services/medical_profile_cache_service.dart';
import '../../data/repositories/firebase_medical_profile_repository.dart';
import '../../domain/models/medical_profile.dart';
import '../../domain/repositories/medical_profile_repository.dart';

final medicalProfileCacheProvider = Provider<MedicalProfileCacheService>((ref) {
  return MedicalProfileCacheService(ref.watch(sharedPreferencesProvider));
});

final medicalProfileRepositoryProvider = Provider<MedicalProfileRepository>((ref) {
  return FirebaseMedicalProfileRepository(
    cacheService: ref.watch(medicalProfileCacheProvider),
  );
});

final medicalProfileProvider = StateNotifierProvider<MedicalProfileController, AsyncValue<MedicalProfile?>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) {
    return MedicalProfileController(ref.watch(medicalProfileRepositoryProvider), '')..clear();
  }
  return MedicalProfileController(ref.watch(medicalProfileRepositoryProvider), user.id)..loadProfile();
});

class MedicalProfileController extends StateNotifier<AsyncValue<MedicalProfile?>> {
  final MedicalProfileRepository _repository;
  final String _uid;

  MedicalProfileController(this._repository, this._uid) : super(const AsyncValue.loading());

  void clear() {
    state = const AsyncValue.data(null);
  }

  Future<void> loadProfile() async {
    if (_uid.isEmpty) return;
    state = const AsyncValue.loading();
    try {
      final profile = await _repository.getProfile(_uid);
      state = AsyncValue.data(profile);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> saveProfile(MedicalProfile profile) async {
    state = const AsyncValue.loading();
    try {
      await _repository.saveProfile(profile);
      state = AsyncValue.data(profile);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<String?> uploadPhoto(File file) async {
    if (_uid.isEmpty) return null;
    return await _repository.uploadProfilePhoto(_uid, file);
  }
}
