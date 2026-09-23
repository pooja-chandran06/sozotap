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

  MedicalProfileController(this._repository, this._uid) : super(const AsyncValue.loading()) {
    SafeLogger.info('[MEDICAL_DEBUG] CONTROLLER CREATED for UID: $_uid');
    SafeLogger.info('[MEDICAL_DEBUG] AUTH UID = $_uid');
    SafeLogger.info('[MEDICAL_DEBUG] PROVIDER STATE = loading');
  }

  @override
  void dispose() {
    SafeLogger.info('[MEDICAL_DEBUG] CONTROLLER DISPOSED for UID: $_uid');
    super.dispose();
  }

  void clear() {
    SafeLogger.info('[MEDICAL_DEBUG] PROVIDER STATE = data (null)');
    state = const AsyncValue.data(null);
  }

  Future<void> loadProfile() async {
    SafeLogger.info('[MEDICAL_DEBUG] FETCH START for UID: $_uid');
    if (_uid.isEmpty) {
      SafeLogger.info('[MEDICAL_DEBUG] AUTH UID is empty, setting AsyncValue.data(null)');
      SafeLogger.info('[MEDICAL_DEBUG] PROVIDER STATE = data (null)');
      SafeLogger.info('[MEDICAL_DEBUG] FETCH END for UID: $_uid');
      state = const AsyncValue.data(null);
      return;
    }
    SafeLogger.info('[MEDICAL_DEBUG] Initiating loadProfile for UID: $_uid');
    state = const AsyncValue.loading();
    SafeLogger.info('[MEDICAL_DEBUG] PROVIDER STATE = loading');
    try {
      final profile = await _repository.getProfile(_uid);
      SafeLogger.info('[MEDICAL_DEBUG] FETCH END for UID: $_uid');
      SafeLogger.info('[MEDICAL_DEBUG] PROVIDER DATA RECEIVED: ${profile != null ? "MedicalProfile(uid: ${profile.uid}, fullName: ${profile.fullName})" : "null"}');
      state = AsyncValue.data(profile);
      SafeLogger.info('[MEDICAL_DEBUG] PROVIDER STATE = data');
    } catch (e, st) {
      SafeLogger.info('[MEDICAL_DEBUG] FETCH END WITH ERROR for UID: $_uid: $e');
      SafeLogger.error('[MEDICAL_DEBUG] PROVIDER STATE = error ($e)', error: e, stackTrace: st);
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> saveProfile(MedicalProfile profile) async {
    final previousState = state;
    SafeLogger.info('[MEDICAL_DEBUG] SAVE START for UID: ${profile.uid}');
    SafeLogger.info('[MEDICAL_DEBUG] SAVE UID = ${profile.uid}');
    try {
      await _repository.saveProfile(profile);
      SafeLogger.info('[MEDICAL_DEBUG] SAVE SUCCEEDED for UID: ${profile.uid}');
      state = AsyncValue.data(profile);
      SafeLogger.info('[MEDICAL_DEBUG] PROVIDER STATE = data (after save)');
    } catch (e, st) {
      SafeLogger.error('[MEDICAL_DEBUG] SAVE FAILED for UID: ${profile.uid}', error: e, stackTrace: st);
      state = previousState;
      rethrow;
    }
  }

  Future<String?> uploadPhoto(File file) async {
    if (_uid.isEmpty) return null;
    return await _repository.uploadProfilePhoto(_uid, file);
  }
}
