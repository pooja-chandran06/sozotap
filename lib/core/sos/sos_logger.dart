import 'package:cloud_firestore/cloud_firestore.dart';
import '../../emergency_contacts/domain/models/emergency_contact.dart';
import '../../utils/logger.dart';
import 'sos_orchestrator.dart';

class SosLogger {
  final FirebaseFirestore _firestore;

  SosLogger({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> logSosEvent(String userId, List<EmergencyContact> contacts, SosChannel channel) async {
    try {
      await _firestore.collection('activity_logs').add({
        'userId': userId,
        'event': 'SOS_TRIGGERED',
        'channel': channel.name,
        'contactsNotified': contacts.map((c) => c.phoneNumber).toList(),
        'timestamp': FieldValue.serverTimestamp(),
      });
      AppLogger.i('SOS event logged successfully for user: $userId');
    } catch (e, st) {
      AppLogger.e('Failed to log SOS event', e, st);
    }
  }
}
