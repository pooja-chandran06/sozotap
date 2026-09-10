import '../../domain/models/emergency_alert_model.dart';

class SosState {
  final int countdownSeconds;
  final bool isCountingDown;
  final bool isActivating;
  final bool isLiveLocationActive;
  final String? activeAlertId;
  final EmergencyAlertModel? currentAlert;
  final String? errorMessage;
  final String? locationStatusMessage;
  final DateTime? lastLocationUpdate;
  final double? lastLocationAccuracy;

  const SosState({
    this.countdownSeconds = 5,
    this.isCountingDown = false,
    this.isActivating = false,
    this.isLiveLocationActive = false,
    this.activeAlertId,
    this.currentAlert,
    this.errorMessage,
    this.locationStatusMessage,
    this.lastLocationUpdate,
    this.lastLocationAccuracy,
  });

  SosState copyWith({
    int? countdownSeconds,
    bool? isCountingDown,
    bool? isActivating,
    bool? isLiveLocationActive,
    String? activeAlertId,
    EmergencyAlertModel? currentAlert,
    String? errorMessage,
    String? locationStatusMessage,
    DateTime? lastLocationUpdate,
    double? lastLocationAccuracy,
    bool clearError = false,
    bool clearActiveAlert = false,
  }) {
    return SosState(
      countdownSeconds: countdownSeconds ?? this.countdownSeconds,
      isCountingDown: isCountingDown ?? this.isCountingDown,
      isActivating: isActivating ?? this.isActivating,
      isLiveLocationActive: isLiveLocationActive ?? this.isLiveLocationActive,
      activeAlertId: clearActiveAlert ? null : (activeAlertId ?? this.activeAlertId),
      currentAlert: clearActiveAlert ? null : (currentAlert ?? this.currentAlert),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      locationStatusMessage: locationStatusMessage ?? this.locationStatusMessage,
      lastLocationUpdate: lastLocationUpdate ?? this.lastLocationUpdate,
      lastLocationAccuracy: lastLocationAccuracy ?? this.lastLocationAccuracy,
    );
  }
}
