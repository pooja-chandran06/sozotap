import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/template_audit_log.dart';
import '../../../utils/logger.dart';

class TemplateAuditLogRepository {
  final FirebaseFirestore _firestore;

  TemplateAuditLogRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> logChange({
    required String templateId,
    required String changedByUid,
    required String action,
    Map<String, dynamic>? before,
    Map<String, dynamic>? after,
  }) async {
    try {
      final logRef = _firestore
          .collection('templates')
          .doc(templateId)
          .collection('audit_logs')
          .doc();

      final log = TemplateAuditLog(
        id: logRef.id,
        templateId: templateId,
        changedByUid: changedByUid,
        timestamp: DateTime.now(),
        action: action,
        before: before,
        after: after,
      );

      await logRef.set(log.toFirestore());
      AppLogger.i('Audit log created for template $templateId by $changedByUid ($action)');
    } catch (e, st) {
      AppLogger.e('Failed to write audit log for template $templateId', e, st);
    }
  }

  Future<List<TemplateAuditLog>> getHistory(String templateId, {int limit = 20}) async {
    try {
      final snapshot = await _firestore
          .collection('templates')
          .doc(templateId)
          .collection('audit_logs')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => TemplateAuditLog.fromFirestore(doc)).toList();
    } catch (e, st) {
      AppLogger.e('Failed to fetch audit history for template $templateId', e, st);
      return [];
    }
  }
}
