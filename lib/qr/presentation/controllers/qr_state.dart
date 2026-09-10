import '../../domain/models/emergency_qr_model.dart';

class QrState {
  final bool isLoading;
  final String? rawPayload; // Raw high-entropy payload held strictly in memory
  final EmergencyQrModel? activeMetadata;
  final String? errorMessage;
  final String? successMessage;

  const QrState({
    this.isLoading = false,
    this.rawPayload,
    this.activeMetadata,
    this.errorMessage,
    this.successMessage,
  });

  QrState copyWith({
    bool? isLoading,
    String? rawPayload,
    EmergencyQrModel? activeMetadata,
    String? errorMessage,
    String? successMessage,
    bool clearPayload = false,
    bool clearMetadata = false,
    bool clearError = false,
  }) {
    return QrState(
      isLoading: isLoading ?? this.isLoading,
      rawPayload: clearPayload ? null : (rawPayload ?? this.rawPayload),
      activeMetadata: clearMetadata ? null : (activeMetadata ?? this.activeMetadata),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: successMessage ?? this.successMessage,
    );
  }
}
