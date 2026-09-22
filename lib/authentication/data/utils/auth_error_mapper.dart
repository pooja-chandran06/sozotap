import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';

class AuthErrorMapper {
  static String getMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-credential':
          return 'Invalid email or password. Please check your credentials.';
        case 'user-not-found':
          return 'No account found with this email.';
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
          return 'Too many login attempts. Please try again later.';
        case 'network-request-failed':
          return 'Network error. Please check your internet connection.';
        default:
          return error.message ?? 'An authentication error occurred (${error.code}).';
      }
    } else if (error is TimeoutException) {
      return 'Authentication request timed out. Please check your connection and try again.';
    }

    final str = error.toString();
    if (str.startsWith('Exception: ')) {
      return str.substring(11);
    }
    return str;
  }
}
