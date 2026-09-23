import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sozotap/core/logging/safe_logger.dart';
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
  final uid = ref.watch(authStateProvider.select((asyncUser) => asyncUser.value?.id)) ?? '';
  final repository = ref.watch(medicalProfileRepositoryProvider);
  return MedicalProfileController(repository, uid)..loadProfile();
});

class MedicalProfileController extends StateNotifier<AsyncValue<MedicalProfile?>> {
  final MedicalProfileRepository _repository;
  final String _uid;

  MedicalProfileController(this._repository, this._uid) : super(const AsyncValue.loading());

  void clear() {
    state = const AsyncValue.data(null);
  }

  Future<void> loadProfile() async {
    if (_uid.isEmpty) {
      SafeLogger.info('[MedicalProfileController] Empty UID, setting AsyncValue.data(null)');
      state = const AsyncValue.data(null);
      return;
    }
    SafeLogger.info('[MedicalProfileController] Initiating loadProfile for UID: $_uid');
    state = const AsyncValue.loading();
    try {
      final profile = await _repository.getProfile(_uid);
      SafeLogger.info('[MedicalProfileController] getProfile completed. Profile found: ${profile != null}');
      state = AsyncValue.data(profile);
    } catch (e, st) {
      SafeLogger.error('[MedicalProfileController] Failed to load medical profile for UID: $_uid', error: e, stackTrace: st);
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> saveProfile(MedicalProfile profile) async {
    final previousState = state;
    SafeLogger.info('[MedicalProfileController] Initiating saveProfile for UID: ${profile.uid}');
    try {
      await _repository.saveProfile(profile);
      SafeLogger.info('[MedicalProfileController] saveProfile SUCCEEDED for UID: ${profile.uid}');
      state = AsyncValue.data(profile);
    } catch (e, st) {
      SafeLogger.error('[MedicalProfileController] saveProfile FAILED for UID: ${profile.uid}', error: e, stackTrace: st);
      state = previousState;
      rethrow;
    }
  }

  Future<String?> uploadPhoto(File file) async {
    if (_uid.isEmpty) return null;
    return await _repository.uploadProfilePhoto(_uid, file);
  }
}
