import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../data/repositories/firebase_auth_repository.dart';
import '../../data/utils/auth_error_mapper.dart';
import '../../../utils/logger.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return FirebaseAuthRepository();
});

final authStateProvider = StreamProvider<AppUser?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

final authControllerProvider = StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  return AuthController(ref.watch(authRepositoryProvider));
});

class AuthController extends StateNotifier<AsyncValue<void>> {
  final AuthRepository _authRepository;

  AuthController(this._authRepository) : super(const AsyncValue.data(null));

  Future<void> signInWithEmail(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      await _authRepository.signInWithEmail(email, password);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      AppLogger.e('Sign in error', e, st);
      state = AsyncValue.error(AuthErrorMapper.getMessage(e), st);
    }
  }

  Future<void> registerWithEmail(String email, String password, String displayName) async {
    state = const AsyncValue.loading();
    try {
      await _authRepository.registerWithEmail(email, password, displayName);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      AppLogger.e('Register error', e, st);
      state = AsyncValue.error(AuthErrorMapper.getMessage(e), st);
    }
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    try {
      await _authRepository.signInWithGoogle();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      AppLogger.e('Google sign in error', e, st);
      state = AsyncValue.error(AuthErrorMapper.getMessage(e), st);
    }
  }

  Future<void> resetPassword(String email) async {
    state = const AsyncValue.loading();
    try {
      await _authRepository.resetPassword(email);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      AppLogger.e('Reset password error', e, st);
      state = AsyncValue.error(AuthErrorMapper.getMessage(e), st);
    }
  }

  Future<void> sendEmailVerification() async {
    state = const AsyncValue.loading();
    try {
      await _authRepository.sendEmailVerification();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      AppLogger.e('Email verification error', e, st);
      state = AsyncValue.error(AuthErrorMapper.getMessage(e), st);
    }
  }

  Future<void> reloadUser() async {
    state = const AsyncValue.loading();
    try {
      await _authRepository.reloadUser();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      AppLogger.e('Reload user error', e, st);
      state = AsyncValue.error(AuthErrorMapper.getMessage(e), st);
    }
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      await _authRepository.signOut();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      AppLogger.e('Sign out error', e, st);
      state = AsyncValue.error(AuthErrorMapper.getMessage(e), st);
    }
  }
}
