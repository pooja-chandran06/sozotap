import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/emergency_qr_model.dart';
import '../../domain/repositories/emergency_qr_repository.dart';
import 'qr_state.dart';

import 'package:sozotap/core/logging/safe_logger.dart';

class QrController extends StateNotifier<QrState> {
  final EmergencyQrRepository _repository;

  QrController(this._repository) : super(const QrState()) {
    SafeLogger.info('[TRACE_QR] CONTROLLER_CREATED');
  }

  @override
  void dispose() {
    SafeLogger.info('[TRACE_QR] CONTROLLER_DISPOSED');
    super.dispose();
  }

  Future<void> issueOrCreateQr() async {
    SafeLogger.info('[TRACE_QR] CONTROLLER_START issueOrCreateQr');
    state = state.copyWith(isLoading: true, clearError: true);
    try {
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

      SafeLogger.info('[TRACE_QR] CONTROLLER_SUCCESS tokenId=${metadata.tokenId}');

      state = state.copyWith(
        isLoading: false,
        rawPayload: rawPayload,
        activeMetadata: metadata,
        successMessage: 'Emergency QR code created successfully.',
      );
    } catch (e, stackTrace) {
      SafeLogger.error('[TRACE_QR] ERROR: $e', error: e, stackTrace: stackTrace);
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to issue emergency QR code: $e',
      );
    } finally {
      SafeLogger.info('[TRACE_QR] FINALLY');
      if (state.isLoading) {
        state = state.copyWith(isLoading: false);
      }
    }
  }

  Future<void> regenerateQr() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      SafeLogger.info('Regenerating Emergency QR via Cloud Function...');
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
    } catch (e, stackTrace) {
      SafeLogger.error('Error regenerating QR code: $e', error: e, stackTrace: stackTrace);
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to regenerate emergency QR code: $e',
      );
    }
  }

  Future<void> revokeQr(String tokenId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      SafeLogger.info('Revoking Emergency QR tokenId: $tokenId');
      await _repository.revokeEmergencyQr(tokenId);

      state = state.copyWith(
        isLoading: false,
        clearPayload: true,
        clearMetadata: true,
        successMessage: 'Emergency QR code revoked successfully.',
      );
    } catch (e, stackTrace) {
      SafeLogger.error('Error revoking QR code: $e', error: e, stackTrace: stackTrace);
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
