import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:logger/logger.dart';
import '../../../config/app_config.dart';

class LocationCaptureResult {
  final double? latitude;
  final double? longitude;
  final double? accuracy;
  final DateTime? capturedAt;
  final String status; // 'available', 'unavailable', 'permissionDenied', 'serviceDisabled'
  final String? failureReason;
  final String userFriendlyMessage;

  const LocationCaptureResult({
    this.latitude,
    this.longitude,
    this.accuracy,
    this.capturedAt,
    required this.status,
    this.failureReason,
    required this.userFriendlyMessage,
  });
}

class LocationServiceHelper {
  static final Logger _logger = Logger();

  static Future<LocationCaptureResult> captureCurrentLocation() async {
    try {
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (kDebugMode) _logger.w('Location services disabled on device.');
        return const LocationCaptureResult(
          status: 'serviceDisabled',
          failureReason: 'Location services are disabled on device.',
          userFriendlyMessage: 'Location services are turned off on your device.',
        );
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        if (kDebugMode) _logger.i('Location permission denied, requesting...');
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (kDebugMode) _logger.w('Location permission denied by user.');
          return const LocationCaptureResult(
            status: 'permissionDenied',
            failureReason: 'Location permission denied by user.',
            userFriendlyMessage: 'Location permission was denied.',
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (kDebugMode) _logger.w('Location permission denied forever.');
        return const LocationCaptureResult(
          status: 'permissionDenied',
          failureReason: 'Location permission permanently denied. Enable in device settings.',
          userFriendlyMessage: 'Location permission is permanently denied. Please enable in Settings.',
        );
      }

      if (kDebugMode) _logger.i('Capturing current position via Geolocator...');
      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 8),
      );

      final now = DateTime.now();
      if (kDebugMode) _logger.i('Location captured successfully.');

      return LocationCaptureResult(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        capturedAt: now,
        status: 'available',
        userFriendlyMessage: 'Location acquired successfully.',
      );
    } on TimeoutException {
      if (kDebugMode) _logger.w('GPS location capture timed out after 8s');
      return const LocationCaptureResult(
        status: 'unavailable',
        failureReason: 'GPS location fix timed out after 8 seconds.',
        userFriendlyMessage: 'Could not acquire precise GPS fix in time.',
      );
    } catch (e, stackTrace) {
      _logger.e('Error capturing location', error: e, stackTrace: stackTrace);
      return LocationCaptureResult(
        status: 'unavailable',
        failureReason: 'Location capture error: ${e.toString()}',
        userFriendlyMessage: 'Unable to capture location: ${e.toString()}',
      );
    }
  }

  /// Create a position stream configured with distance filtering and high accuracy.
  static Stream<Position> getLivePositionStream({
    int distanceFilter = AppConfig.liveLocationDistanceFilterMeters,
  }) {
    late LocationSettings locationSettings;

    if (defaultTargetPlatform == TargetPlatform.android) {
      locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: distanceFilter,
        forceLocationManager: false,
        intervalDuration: const Duration(seconds: 15),
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      locationSettings = AppleSettings(
        accuracy: LocationAccuracy.high,
        activityType: ActivityType.fitness,
        distanceFilter: distanceFilter,
        pauseLocationUpdatesAutomatically: true,
      );
    } else {
      locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: distanceFilter,
      );
    }

    return Geolocator.getPositionStream(locationSettings: locationSettings);
  }
}
