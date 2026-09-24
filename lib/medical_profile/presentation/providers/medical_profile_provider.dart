import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
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
  final uid = ref.watch(authStateProvider.select((asyncUser) => asyncUser.value?.id)) ??
      FirebaseAuth.instance.currentUser?.uid ??
      '';
  final repository = ref.watch(medicalProfileRepositoryProvider);
  return MedicalProfileController(repository, uid)..loadProfile();
});

class MedicalProfileController extends StateNotifier<AsyncValue<MedicalProfile?>> {
  final MedicalProfileRepository _repository;
  final String _uid;

  MedicalProfileController(this._repository, this._uid) : super(const AsyncValue.loading()) {
    SafeLogger.info('[MEDICAL_PROFILE_DEBUG] Controller created for uid=$_uid');
  }

  void clear() {
    SafeLogger.info('[MEDICAL_PROFILE_DEBUG] Controller clear for uid=$_uid');
    state = const AsyncValue.data(null);
  }

  Future<void> loadProfile({bool showLoadingIndicator = true}) async {
    SafeLogger.info('[MEDICAL_PROFILE_DEBUG] uid=$_uid loadProfile started');

    if (_uid.isEmpty) {
      SafeLogger.info('[MEDICAL_PROFILE_DEBUG] uid is empty, state = AsyncValue.data(null)');
      state = const AsyncValue.data(null);
      return;
    }

    if (showLoadingIndicator || !state.hasValue) {
      state = const AsyncValue.loading();
    }

    try {
      final profile = await _repository.getProfile(_uid);
      SafeLogger.info(
        '[MEDICAL_PROFILE_DEBUG] uid=$_uid loadProfile completed: '
        '${profile != null ? "profile found (${profile.fullName})" : "no profile document"}',
      );
      state = AsyncValue.data(profile);
    } catch (e, st) {
      SafeLogger.error(
        '[MEDICAL_PROFILE_DEBUG] uid=$_uid loadProfile failed: $e',
        error: e,
        stackTrace: st,
      );
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> saveProfile(MedicalProfile profile) async {
    final previousState = state;
    SafeLogger.info('[MEDICAL_PROFILE_DEBUG] uid=${profile.uid} saveProfile started');

    try {
      await _repository.saveProfile(profile);
      SafeLogger.info('[MEDICAL_PROFILE_DEBUG] uid=${profile.uid} saveProfile succeeded');
      state = AsyncValue.data(profile);
    } catch (e, st) {
      SafeLogger.error(
        '[MEDICAL_PROFILE_DEBUG] uid=${profile.uid} saveProfile failed: $e',
        error: e,
        stackTrace: st,
      );
      state = previousState;
      rethrow;
    }
  }

  Future<String?> uploadPhoto(File file) async {
    if (_uid.isEmpty) return null;
    return await _repository.uploadProfilePhoto(_uid, file);
  }
}
