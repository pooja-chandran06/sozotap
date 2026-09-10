class AppConfig {
  /// Default emergency number for direct dialing.
  /// IMPORTANT: Production deployments must localize this per country/region (e.g. 911 in US/CA, 112 in EU/IN, 999 in UK).
  static const String defaultEmergencyNumber = '911';

  /// Live Location Tracking Throttling Configuration
  /// Minimum distance change (in meters) required before emitting position update.
  static const int liveLocationDistanceFilterMeters = 25;

  /// Minimum time duration between consecutive Firestore writes for live location updates.
  static const Duration liveLocationMinWriteInterval = Duration(seconds: 30);

  /// Maximum duration (in minutes) an active SOS session can remain open before auto-expiring.
  static const Duration sosMaxActiveDuration = Duration(minutes: 30);
}
