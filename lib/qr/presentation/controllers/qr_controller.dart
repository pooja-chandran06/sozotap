import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../../domain/models/emergency_qr_model.dart';
import '../../domain/repositories/emergency_alert_repository.dart';
import '../../domain/repositories/emergency_qr_repository.dart';
import 'qr_state.dart';

class QrController extends StateNotifier<QrState> {
  final EmergencyQrRepository _repository;
  final Logger _logger = Logger();

  QrController(this._repository) : super(const QrState());

  Future<void> issueOrCreateQr() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      _logger.i('Issuing new Emergency QR via Cloud Function...');
      final result = await _repository.createEmergencyQr();

      final rawPayload = result['rawPayload'] as String?;
      final tokenId = result['tokenId'] as String? ?? '';
      final displayEmergencyId = result['displayEmergencyId'] as String? ?? '';
      final expiresAtStr = result['expiresAt'] as String?;

      final metadata = EmergencyQrModel(
        tokenId: tokenId,
        ownerUserId: '',
        status: 'active',
        createdAt: DateTime.now(),
        expiresAt: expiresAtStr != null ? DateTime.tryParse(expiresAtStr) : null,
        scanCount: 0,
        allowedFieldsVersion: 1,
        emergencyProfileVersion: 1,
        displayEmergencyId: displayEmergencyId,
        notificationOnScan: true,
        rawPayload: rawPayload,
      );

      state = state.copyWith(
        isLoading: false,
        rawPayload: rawPayload,
        activeMetadata: metadata,
        successMessage: 'Emergency QR code created successfully.',
      );
    } catch (e) {
      _logger.e('Error issuing emergency QR code: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to issue emergency QR code: $e',
      );
    }
  }

  Future<void> regenerateQr() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      _logger.i('Regenerating Emergency QR via Cloud Function...');
      final result = await _repository.regenerateEmergencyQr();

      final rawPayload = result['rawPayload'] as String?;
      final tokenId = result['tokenId'] as String? ?? '';
      final displayEmergencyId = result['displayEmergencyId'] as String? ?? '';
      final expiresAtStr = result['expiresAt'] as String?;

      final metadata = EmergencyQrModel(
        tokenId: tokenId,
        ownerUserId: '',
        status: 'active',
        createdAt: DateTime.now(),
        expiresAt: expiresAtStr != null ? DateTime.tryParse(expiresAtStr) : null,
        scanCount: 0,
        allowedFieldsVersion: 1,
        emergencyProfileVersion: 1,
        displayEmergencyId: displayEmergencyId,
        notificationOnScan: true,
        rawPayload: rawPayload,
      );

      state = state.copyWith(
        isLoading: false,
        rawPayload: rawPayload,
        activeMetadata: metadata,
        successMessage: 'Emergency QR code regenerated. Previous codes revoked.',
      );
    } catch (e) {
      _logger.e('Error regenerating QR code: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to regenerate emergency QR code: $e',
      );
    }
  }

  Future<void> revokeQr(String tokenId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      _logger.i('Revoking Emergency QR tokenId: $tokenId');
      await _repository.revokeEmergencyQr(tokenId);

      state = state.copyWith(
        isLoading: false,
        clearPayload: true,
        clearMetadata: true,
        successMessage: 'Emergency QR code revoked successfully.',
      );
    } catch (e) {
      _logger.e('Error revoking QR code: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to revoke QR code: $e',
      );
    }
  }

  void updateMetadataFromStream(EmergencyQrModel? metadata) {
    if (metadata != null) {
      state = state.copyWith(
        activeMetadata: metadata,
        rawPayload: state.rawPayload ?? metadata.rawPayload,
      );
    } else {
      state = state.copyWith(clearMetadata: true, clearPayload: true);
    }
  }
}
