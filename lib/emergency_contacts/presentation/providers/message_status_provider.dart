import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/sos/message_status.dart';

final messageStatusProvider = StreamProvider.family<MessageDeliveryStatus?, String>((ref, messageId) {
  return FirebaseFirestore.instance
      .collection('messages')
      .doc(messageId)
      .snapshots()
      .asyncMap((smsSnapshot) async {
        if (smsSnapshot.exists && smsSnapshot.data() != null) {
          return _mapSnapshotToStatus(smsSnapshot, messageId, 'sms');
        } else {
          final emailSnapshot = await FirebaseFirestore.instance.collection('emails').doc(messageId).get();
          if (emailSnapshot.exists && emailSnapshot.data() != null) {
            return _mapSnapshotToStatus(emailSnapshot, messageId, 'email');
          } else {
            final pushSnapshot = await FirebaseFirestore.instance.collection('push_notifications').doc(messageId).get();
            if (pushSnapshot.exists && pushSnapshot.data() != null) {
              return _mapSnapshotToStatus(pushSnapshot, messageId, 'push');
            }
          }
        }
        return null;
      });
});

MessageDeliveryStatus _mapSnapshotToStatus(DocumentSnapshot snapshot, String messageId, String channel) {
  final data = snapshot.data() as Map<String, dynamic>;
  return MessageDeliveryStatus(
    messageId: messageId,
    userId: data['userId'] as String? ?? 'unknown',
    recipient: (data['to'] ?? data['toUserId']) as String? ?? 'unknown',
    status: MessageStatus.values.firstWhere(
      (e) => e.name == data['status'],
      orElse: () => MessageStatus.queued,
    ),
    channel: data['channel'] as String? ?? channel,
    createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    errorMessage: data['errorMessage'] as String?,
  );
}
