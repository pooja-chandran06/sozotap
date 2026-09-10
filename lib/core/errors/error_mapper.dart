import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:sozotap/core/errors/app_exception.dart';

class ErrorMapper {
  /// Map any raw exception/error to a clean, user-friendly [AppException]
  static AppException fromError(dynamic error) {
    if (error is AppException) {
      return error;
    }

    if (error is fb_auth.FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return AuthException('Invalid email or password. Please try again.', code: error.code, originalError: error);
        case 'user-disabled':
          return AuthException('This account has been disabled. Please contact support.', code: error.code, originalError: error);
        case 'email-already-in-use':
          return AuthException('An account with this email already exists.', code: error.code, originalError: error);
        case 'weak-password':
          return AuthException('The password provided is too weak.', code: error.code, originalError: error);
        case 'network-request-failed':
          return NetworkException('Network error occurred. Please check your connection.', code: error.code, originalError: error);
        case 'too-many-requests':
          return AuthException('Too many unsuccessful attempts. Please try again later.', code: error.code, originalError: error);
        default:
          return AuthException(error.message ?? 'Authentication error occurred.', code: error.code, originalError: error);
      }
    }

    if (error is firestore.FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return PermissionException('Access denied. You do not have permission to perform this action.', code: error.code, originalError: error);
        case 'unavailable':
          return NetworkException('Service is temporarily unavailable. Operating in offline mode.', code: error.code, originalError: error);
        case 'not-found':
          return ServerException('The requested resource was not found.', code: error.code, originalError: error);
        case 'already-exists':
          return ValidationException('Resource already exists.', code: error.code, originalError: error);
        default:
          return ServerException(error.message ?? 'Database error occurred.', code: error.code, originalError: error);
      }
    }

    if (error is SocketException || error is TimeoutException) {
      return NetworkException('Network connection failed. Please verify your internet connection.', originalError: error);
    }

    if (error is FormatException) {
      return ValidationException('Invalid data format received.', originalError: error);
    }

    return ServerException(
      'An unexpected error occurred: ${error.toString().split('\n').first}',
      originalError: error,
    );
  }

  /// Get user facing error message
  static String toUserMessage(dynamic error) {
    final appEx = fromError(error);
    return appEx.message;
  }
}
