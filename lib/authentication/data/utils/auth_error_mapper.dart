import 'package:firebase_auth/firebase_auth.dart';

class AuthErrorMapper {
  static String getMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'No user found with this email.';
        case 'wrong-password':
          return 'Incorrect password. Please try again.';
        case 'invalid-email':
          return 'The email address is not valid.';
        case 'user-disabled':
          return 'This user account has been disabled.';
        case 'email-already-in-use':
          return 'An account already exists for this email.';
        case 'operation-not-allowed':
          return 'This authentication method is disabled.';
        case 'weak-password':
          return 'The password provided is too weak.';
        case 'requires-recent-login':
          return 'Please log in again to perform this action.';
        case 'too-many-requests':
          return 'Too many requests. Please try again later.';
        default:
          return error.message ?? 'An unknown authentication error occurred.';
      }
    }
    return error.toString();
  }
}
