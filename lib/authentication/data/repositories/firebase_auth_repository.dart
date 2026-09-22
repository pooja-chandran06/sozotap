import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sozotap/core/logging/safe_logger.dart';
import '../../domain/models/app_user.dart';
import '../../domain/repositories/auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  FirebaseAuthRepository({FirebaseAuth? firebaseAuth, GoogleSignIn? googleSignIn})
      : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  AppUser? _mapFirebaseUser(User? user) {
    if (user == null) return null;
    return AppUser(
      id: user.uid,
      email: user.email ?? '',
      displayName: user.displayName ?? '',
      isEmailVerified: user.emailVerified,
    );
  }

  @override
  Stream<AppUser?> get authStateChanges {
    return _firebaseAuth.authStateChanges().map(_mapFirebaseUser);
  }

  @override
  AppUser? get currentUser => _mapFirebaseUser(_firebaseAuth.currentUser);

  @override
  Future<void> registerWithEmail(String email, String password, String displayName) async {
    SafeLogger.info('Attempting registerWithEmail');
    final userCredential = await _firebaseAuth
        .createUserWithEmailAndPassword(
          email: email,
          password: password,
        )
        .timeout(
          const Duration(seconds: 20),
          onTimeout: () => throw TimeoutException('Registration request timed out'),
        );
    await userCredential.user?.updateDisplayName(displayName);
    await sendEmailVerification();
  }

  @override
  Future<void> signInWithEmail(String email, String password) async {
    SafeLogger.info('Initiating FirebaseAuth.signInWithEmailAndPassword for: $email');
    final stopwatch = Stopwatch()..start();
    try {
      final credential = await _firebaseAuth
          .signInWithEmailAndPassword(
            email: email,
            password: password,
          )
          .timeout(
            const Duration(seconds: 20),
            onTimeout: () {
              SafeLogger.error('signInWithEmailAndPassword TIMED OUT after ${stopwatch.elapsed.inSeconds}s');
              throw TimeoutException('Login request timed out after 20 seconds. Please check network connectivity or Firebase configuration.');
            },
          );
      stopwatch.stop();
      SafeLogger.info('FirebaseAuth.signInWithEmailAndPassword SUCCEEDED in ${stopwatch.elapsedMilliseconds}ms. UID: ${credential.user?.uid}');
    } on FirebaseAuthException catch (e, st) {
      stopwatch.stop();
      SafeLogger.error('FirebaseAuthException during signInWithEmail [code: ${e.code}] [message: ${e.message}]', error: e, stackTrace: st);
      rethrow;
    } on TimeoutException catch (e, st) {
      stopwatch.stop();
      SafeLogger.error('TimeoutException during signInWithEmail: ${e.message}', error: e, stackTrace: st);
      rethrow;
    } catch (e, st) {
      stopwatch.stop();
      final errStr = e.toString().toLowerCase();
      if (errStr.contains('network') || errStr.contains('socket') || errStr.contains('connection')) {
        SafeLogger.error('Network failure during signInWithEmail: $e', error: e, stackTrace: st);
      } else if (errStr.contains('appcheck') || errStr.contains('app-check')) {
        SafeLogger.error('App Check failure during signInWithEmail: $e', error: e, stackTrace: st);
      } else {
        SafeLogger.error('Unexpected exception during signInWithEmail: $e', error: e, stackTrace: st);
      }
      rethrow;
    }
  }

  @override
  Future<void> signInWithGoogle() async {
    SafeLogger.info('Initiating Google Sign-In');
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn().timeout(
          const Duration(seconds: 30),
          onTimeout: () => throw TimeoutException('Google Sign-In timed out'),
        );
    if (googleUser == null) return;

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    await _firebaseAuth.signInWithCredential(credential).timeout(
          const Duration(seconds: 20),
          onTimeout: () => throw TimeoutException('Firebase Google sign-in timed out'),
        );
  }

  @override
  Future<void> signOut() async {
    await Future.wait([
      _firebaseAuth.signOut(),
      if (await _googleSignIn.isSignedIn()) _googleSignIn.signOut(),
    ]).timeout(
      const Duration(seconds: 15),
      onTimeout: () => [],
    );
  }

  @override
  Future<void> resetPassword(String email) async {
    await _firebaseAuth.sendPasswordResetEmail(email: email).timeout(
          const Duration(seconds: 20),
          onTimeout: () => throw TimeoutException('Password reset request timed out'),
        );
  }

  @override
  Future<void> sendEmailVerification() async {
    final user = _firebaseAuth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification().timeout(
            const Duration(seconds: 20),
            onTimeout: () => throw TimeoutException('Email verification request timed out'),
          );
    }
  }

  @override
  Future<void> reloadUser() async {
    await _firebaseAuth.currentUser?.reload().timeout(
          const Duration(seconds: 15),
          onTimeout: () => null,
        );
  }
}
