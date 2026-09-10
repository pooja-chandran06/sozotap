import 'package:flutter/foundation.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:sozotap/core/logging/safe_logger.dart';

class AppCheckService {
  final FirebaseAppCheck _appCheck;

  AppCheckService({FirebaseAppCheck? appCheck})
      : _appCheck = appCheck ?? FirebaseAppCheck.instance;

  Future<void> initialize() async {
    try {
      if (kDebugMode) {
        SafeLogger.info('Initializing Firebase App Check with DEBUG provider');
        await _appCheck.activate(
          androidProvider: AndroidProvider.debug,
          appleProvider: AppleProvider.debug,
        );
      } else {
        SafeLogger.info('Initializing Firebase App Check with Play Integrity / DeviceCheck');
        await _appCheck.activate(
          androidProvider: AndroidProvider.playIntegrity,
          appleProvider: AppleProvider.deviceCheck,
        );
      }
      SafeLogger.info('Firebase App Check initialized successfully');
    } catch (e, stackTrace) {
      SafeLogger.warn(
        'Firebase App Check failed to initialize (non-fatal): $e',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<String?> getToken({bool forceRefresh = false}) async {
    try {
      return await _appCheck.getToken(forceRefresh);
    } catch (e) {
      SafeLogger.error('Failed to retrieve App Check token', error: e);
      return null;
    }
  }
}
