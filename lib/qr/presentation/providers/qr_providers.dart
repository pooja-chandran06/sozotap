import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/emergency_qr_model.dart';
import '../../domain/repositories/emergency_qr_repository.dart';
import '../../data/repositories/firebase_emergency_qr_repository.dart';
import '../controllers/qr_controller.dart';
import '../controllers/qr_state.dart';

final emergencyQrRepositoryProvider = Provider<EmergencyQrRepository>((ref) {
  return FirebaseEmergencyQrRepository();
});

final qrControllerProvider = StateNotifierProvider<QrController, QrState>((ref) {
  final repository = ref.watch(emergencyQrRepositoryProvider);
  return QrController(repository);
});

final watchActiveQrMetadataProvider = StreamProvider<EmergencyQrModel?>((ref) {
  final repository = ref.watch(emergencyQrRepositoryProvider);
  return repository.watchActiveQrMetadata();
});
