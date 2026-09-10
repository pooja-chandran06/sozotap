import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';

import '../../../config/app_config.dart';
import '../../domain/models/emergency_alert_model.dart';
import '../../domain/repositories/emergency_alert_repository.dart';
import '../../core/utils/location_service_helper.dart';
import '../../core/utils/sos_error_mapper.dart';
import '../../../emergency_contacts/presentation/providers/emergency_contacts_provider.dart';
import 'sos_state.dart';

class SosController extends StateNotifier<SosState> {
  final EmergencyAlertRepository _repository;
  final Ref _ref;
  Timer? _countdownTimer;
  Timer? _autoExpireTimer;
  StreamSubscription<Position>? _locationSubscription;
  DateTime? _lastFirestoreWriteTime;
  final Logger _logger = Logger();

  SosController(this._repository, this._ref) : super(const SosState());

  void startCountdown() {
    _countdownTimer?.cancel();
    state = state.copyWith(
      countdownSeconds: 5,
      isCountingDown: true,
      isActivating: false,
      clearError: true,
    );

    if (kDebugMode) _logger.i('SOS Countdown started: 5 seconds');
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.countdownSeconds > 1) {
        state = state.copyWith(countdownSeconds: state.countdownSeconds - 1);
      } else {
        _countdownTimer?.cancel();
        state = state.copyWith(
          countdownSeconds: 0,
          isCountingDown: false,
        );
        if (kDebugMode) _logger.i('SOS Countdown reached 0. Activating SOS...');
        triggerSos();
      }
    });
  }

  void cancelCountdown() {
    if (kDebugMode) _logger.i('SOS Countdown cancelled by user.');
    _countdownTimer?.cancel();
    _countdownTimer = null;
    stopLiveLocationTracking(state.activeAlertId);
    state = const SosState();
  }

  Future<String?> triggerSos() async {
    if (state.isActivating) {
      _logger.w('SOS activation already in progress.');
      return state.activeAlertId;
    }

    state = state.copyWith(
      isActivating: true,
      clearError: true,
    );

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw FirebaseAuthException(
          code: 'unauthenticated',
          message: 'User must be signed in to trigger an SOS alert.',
        );
      }

      final contactIds = <String>[];
      try {
        final contactsState = _ref.read(emergencyContactsProvider);
        for (final contact in contactsState.contacts) {
          if (contact.id.isNotEmpty) {
            contactIds.add(contact.id);
          }
        }
      } catch (e) {
        _logger.w('Could not read emergency contacts: $e');
      }

      final locationResult = await LocationServiceHelper.captureCurrentLocation();

      final alertId = const Uuid().v4();
      final now = DateTime.now();

      final alert = EmergencyAlertModel(
        alertId: alertId,
        ownerUserId: currentUser.uid,
        status: 'active',
        type: 'manual_sos',
        message: 'EMERGENCY SOS: User triggered manual emergency alert in SOZOTAP.',
        createdAt: now,
        updatedAt: now,
        resolvedAt: null,
        lastLocationUpdateAt: locationResult.capturedAt,
        latitude: locationResult.latitude,
        longitude: locationResult.longitude,
        accuracyMeters: locationResult.accuracy,
        locationCapturedAt: locationResult.capturedAt,
        locationStatus: locationResult.status,
        liveLocationEnabled: false, // Default off until user enables
        expiresAt: now.add(AppConfig.sosMaxActiveDuration),
        recipientContactIds: contactIds,
        notificationStatus: 'pending',
        failureReason: locationResult.failureReason,
      );

      if (kDebugMode) _logger.i('Writing EmergencyAlertModel to Firestore: $alertId');
      await _repository.createAlert(alert);

      _startAutoExpireTimer(alertId);

      state = state.copyWith(
        isActivating: false,
        activeAlertId: alertId,
        currentAlert: alert,
        locationStatusMessage: locationResult.userFriendlyMessage,
        lastLocationUpdate: locationResult.capturedAt,
        lastLocationAccuracy: locationResult.accuracy,
      );

      return alertId;
    } catch (e, stackTrace) {
      _logger.e('Error during SOS activation', error: e, stackTrace: stackTrace);
      final errorMsg = SosErrorMapper.mapError(e);
      state = state.copyWith(
        isActivating: false,
        errorMessage: errorMsg,
      );
      return null;
    }
  }

  /// Start live location tracking with write throttling (max once per 30 seconds)
  Future<void> startLiveLocationTracking(String alertId) async {
    if (_locationSubscription != null) {
      _logger.w('Live location stream subscription already active.');
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      state = state.copyWith(errorMessage: 'Authentication required for live location.');
      return;
    }

    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      state = state.copyWith(errorMessage: 'Location services are disabled on your device.');
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        state = state.copyWith(errorMessage: 'Location permission denied.');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      state = state.copyWith(errorMessage: 'Location permission permanently denied.');
      return;
    }

    try {
      await _repository.setLiveLocationEnabled(alertId: alertId, enabled: true);
      state = state.copyWith(
        isLiveLocationActive: true,
        currentAlert: state.currentAlert?.copyWith(liveLocationEnabled: true),
      );

      _lastFirestoreWriteTime = null; // Reset throttling timestamp

      _locationSubscription = LocationServiceHelper.getLivePositionStream().listen(
        (Position position) async {
          final now = DateTime.now();

          // Throttling check: Ensure write interval is respected (default: 30 seconds)
          final bool shouldWrite = _lastFirestoreWriteTime == null ||
              now.difference(_lastFirestoreWriteTime!) >= AppConfig.liveLocationMinWriteInterval;

          if (shouldWrite) {
            _lastFirestoreWriteTime = now;
            try {
              await _repository.updateLiveLocation(
                alertId: alertId,
                latitude: position.latitude,
                longitude: position.longitude,
                accuracyMeters: position.accuracy,
                capturedAt: now,
              );
            } catch (e) {
              _logger.e('Failed to write location update to Firestore: $e');
            }
          }

          state = state.copyWith(
            lastLocationUpdate: now,
            lastLocationAccuracy: position.accuracy,
            locationStatusMessage: 'Live location streaming active.',
          );
        },
        onError: (dynamic error) {
          _logger.e('Live location stream error: $error');
          state = state.copyWith(
            errorMessage: 'Live location connection interrupted.',
          );
        },
        cancelOnError: false,
      );
    } catch (e) {
      _logger.e('Error starting live location tracking: $e');
      state = state.copyWith(errorMessage: SosErrorMapper.mapError(e));
    }
  }

  /// Stop live location tracking and cancel stream
  Future<void> stopLiveLocationTracking(String? alertId) async {
    if (_locationSubscription != null) {
      if (kDebugMode) _logger.i('Cancelling live location stream subscription.');
      await _locationSubscription?.cancel();
      _locationSubscription = null;
    }

    if (alertId != null && alertId.isNotEmpty) {
      try {
        await _repository.setLiveLocationEnabled(alertId: alertId, enabled: false);
      } catch (e) {
        _logger.w('Could not update liveLocationEnabled=false in Firestore: $e');
      }
    }

    state = state.copyWith(
      isLiveLocationActive: false,
      currentAlert: state.currentAlert?.copyWith(liveLocationEnabled: false),
    );
  }

  Future<void> stopSos(String alertId) async {
    try {
      if (kDebugMode) _logger.i('Stopping SOS Alert: $alertId');
      state = state.copyWith(isActivating: true, clearError: true);

      await stopLiveLocationTracking(alertId);
      _autoExpireTimer?.cancel();

      final now = DateTime.now();
      await _repository.updateAlertStatus(
        alertId: alertId,
        status: 'resolved',
        resolvedAt: now,
      );

      state = state.copyWith(
        isActivating: false,
        clearActiveAlert: true,
        currentAlert: state.currentAlert?.copyWith(
          status: 'resolved',
          resolvedAt: now,
          updatedAt: now,
          liveLocationEnabled: false,
        ),
      );
    } catch (e, stackTrace) {
      _logger.e('Error stopping SOS alert', error: e, stackTrace: stackTrace);
      final errorMsg = SosErrorMapper.mapError(e);
      state = state.copyWith(
        isActivating: false,
        errorMessage: errorMsg,
      );
    }
  }

  void _startAutoExpireTimer(String alertId) {
    _autoExpireTimer?.cancel();
    _autoExpireTimer = Timer(AppConfig.sosMaxActiveDuration, () {
      if (state.activeAlertId == alertId) {
        _logger.i('Active SOS session automatically expired after 30 minutes.');
        stopSos(alertId);
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _autoExpireTimer?.cancel();
    _locationSubscription?.cancel();
    _locationSubscription = null;
    super.dispose();
  }
}
