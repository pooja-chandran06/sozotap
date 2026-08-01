import 'package:cloud_firestore/cloud_firestore.dart';

class TemplateAuditLog {
  final String id;
  final String templateId;
  final String changedByUid;
  final DateTime timestamp;
  final String action; // 'create' | 'update' | 'delete' | 'toggle_enabled'
  final Map<String, dynamic>? before;
  final Map<String, dynamic>? after;

  const TemplateAuditLog({
    required this.id,
    required this.templateId,
    required this.changedByUid,
    required this.timestamp,
    required this.action,
    this.before,
    this.after,
  });

  factory TemplateAuditLog.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return TemplateAuditLog(
      id: doc.id,
      templateId: data['templateId'] as String? ?? '',
      changedByUid: data['changedByUid'] as String? ?? 'unknown',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      action: data['action'] as String? ?? 'update',
      before: data['before'] != null ? Map<String, dynamic>.from(data['before'] as Map) : null,
      after: data['after'] != null ? Map<String, dynamic>.from(data['after'] as Map) : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'templateId': templateId,
      'changedByUid': changedByUid,
      'timestamp': FieldValue.serverTimestamp(),
      'action': action,
      if (before != null) 'before': before,
      if (after != null) 'after': after,
    };
  }
}
