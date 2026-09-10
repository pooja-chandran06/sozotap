import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/emergency_alert_model.dart';
import '../../domain/repositories/emergency_alert_repository.dart';
import '../../data/repositories/firebase_emergency_alert_repository.dart';
import '../controllers/sos_controller.dart';
import '../controllers/sos_state.dart';

final emergencyAlertRepositoryProvider = Provider<EmergencyAlertRepository>((ref) {
  return FirebaseEmergencyAlertRepository();
});

final sosControllerProvider = StateNotifierProvider<SosController, SosState>((ref) {
  final repository = ref.watch(emergencyAlertRepositoryProvider);
  return SosController(repository, ref);
});

final watchAlertProvider = StreamProvider.family<EmergencyAlertModel?, String>((ref, alertId) {
  final repository = ref.watch(emergencyAlertRepositoryProvider);
  return repository.watchAlert(alertId);
});
