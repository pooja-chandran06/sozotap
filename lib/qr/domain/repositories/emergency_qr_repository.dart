import '../models/emergency_qr_model.dart';

abstract class EmergencyQrRepository {
  Future<Map<String, dynamic>> createEmergencyQr();
  Future<void> revokeEmergencyQr(String tokenId);
  Future<Map<String, dynamic>> regenerateEmergencyQr();
  Future<EmergencyQrModel?> getActiveQrMetadata();
  Stream<EmergencyQrModel?> watchActiveQrMetadata();
}
