import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SosErrorMapper {
  static String mapError(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
        case 'unauthenticated':
          return 'You must be logged in to send an SOS alert.';
        case 'network-request-failed':
          return 'Network error. Please check your internet connection.';
        default:
          return error.message ?? 'Authentication error encountered.';
      }
    }

    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return 'Access denied to Firestore emergency alerts collection.';
        case 'unavailable':
          return 'Firebase service is currently unavailable. Check internet connectivity.';
        default:
          return error.message ?? 'Database error occurred while processing SOS.';
      }
    }

    if (error is Exception) {
      final msg = error.toString();
      if (msg.contains('Location permission')) {
        return 'Location permission required to send accurate GPS coordinates.';
      }
      return msg.replaceAll('Exception: ', '');
    }

    return error?.toString() ?? 'An unknown error occurred during SOS activation.';
  }
}
