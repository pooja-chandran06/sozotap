import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:sozotap/core/errors/app_exception.dart';
import 'package:sozotap/core/errors/error_mapper.dart';

void main() {
  group('ErrorMapper Unit Tests', () {
    test('maps FirebaseAuthException to AuthException or NetworkException', () {
      final authEx = fb_auth.FirebaseAuthException(
        code: 'user-not-found',
        message: 'No user found for that email.',
      );
      final mapped = ErrorMapper.fromError(authEx);
      expect(mapped, isA<AuthException>());
      expect(mapped.message, 'Invalid email or password. Please try again.');

      final networkAuthEx = fb_auth.FirebaseAuthException(
        code: 'network-request-failed',
      );
      final mappedNetwork = ErrorMapper.fromError(networkAuthEx);
      expect(mappedNetwork, isA<NetworkException>());
    });

    test('maps FirebaseException (Firestore) to PermissionException or NetworkException', () {
      final permEx = firestore.FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
        message: 'The caller does not have permission to execute the specified operation.',
      );
      final mapped = ErrorMapper.fromError(permEx);
      expect(mapped, isA<PermissionException>());

      final unavailEx = firestore.FirebaseException(
        plugin: 'cloud_firestore',
        code: 'unavailable',
      );
      final mappedUnavail = ErrorMapper.fromError(unavailEx);
      expect(mappedUnavail, isA<NetworkException>());
    });

    test('maps SocketException to NetworkException', () {
      final socketEx = const SocketException('Failed host lookup: firestore.googleapis.com');
      final mapped = ErrorMapper.fromError(socketEx);
      expect(mapped, isA<NetworkException>());
      expect(ErrorMapper.toUserMessage(socketEx), contains('Network connection failed'));
    });

    test('passes existing AppException through unchanged', () {
      const original = ValidationException('Field is required');
      final mapped = ErrorMapper.fromError(original);
      expect(mapped, same(original));
    });
  });
}
