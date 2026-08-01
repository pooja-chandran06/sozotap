import '../models/app_user.dart';

abstract class AuthRepository {
  Stream<AppUser?> get authStateChanges;
  AppUser? get currentUser;
  Future<void> signInWithEmail(String email, String password);
  Future<void> registerWithEmail(String email, String password, String displayName);
  Future<void> signInWithGoogle();
  Future<void> signOut();
  Future<void> resetPassword(String email);
  Future<void> sendEmailVerification();
  Future<void> reloadUser();
}
