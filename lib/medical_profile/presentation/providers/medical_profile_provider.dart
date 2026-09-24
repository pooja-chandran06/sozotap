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
    SafeLogger.info('[TRACE_MP] controller CREATED uid=$_uid state=loading');
  }

  @override
  void dispose() {
    SafeLogger.info('[TRACE_MP] controller DISPOSED uid=$_uid');
    super.dispose();
  }

  void clear() {
    SafeLogger.info('[TRACE_MP] controller CLEAR uid=$_uid state=data(null)');
    state = const AsyncValue.data(null);
  }

  Future<void> loadProfile({bool showLoadingIndicator = true}) async {
    SafeLogger.info('[TRACE_MP] loadProfile START uid=$_uid showLoadingIndicator=$showLoadingIndicator');

    if (_uid.isEmpty) {
      SafeLogger.info('[TRACE_MP] uid is empty -> state=data(null)');
      state = const AsyncValue.data(null);
      return;
    }

    if (showLoadingIndicator || !state.hasValue) {
      state = const AsyncValue.loading();
      SafeLogger.info('[TRACE_MP] state=loading');
    }

    try {
      final profile = await _repository.getProfile(_uid);
      SafeLogger.info(
        '[TRACE_MP] loadProfile END uid=$_uid profile=${profile != null ? "found" : "null"}',
      );
      state = AsyncValue.data(profile);
      SafeLogger.info('[TRACE_MP] state=data');
    } catch (e, st) {
      SafeLogger.error(
        '[TRACE_MP] loadProfile ERROR uid=$_uid: $e',
        error: e,
        stackTrace: st,
      );
      state = AsyncValue.error(e, st);
      SafeLogger.info('[TRACE_MP] state=error');
    }
  }

  Future<void> saveProfile(MedicalProfile profile) async {
    final previousState = state;
    SafeLogger.info('[TRACE_SAVE] PROVIDER_UPDATE_START uid=${profile.uid}');

    try {
      await _repository.saveProfile(profile);
      SafeLogger.info('[TRACE_SAVE] PROVIDER_UPDATE_END uid=${profile.uid}');
      state = AsyncValue.data(profile);
      SafeLogger.info('[TRACE_SAVE] PROVIDER_STATE_SET_DATA uid=${profile.uid}');
    } catch (e, st) {
      SafeLogger.error(
        '[TRACE_SAVE] PROVIDER_UPDATE_ERROR uid=${profile.uid}: $e',
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
