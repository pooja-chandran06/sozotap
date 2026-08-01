import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/utils/admin_role_helper.dart';
import 'template_audit_log_repository.dart';

class TemplateMetadata {
  final String id;
  final String type; // 'sms' | 'email' | 'push'
  final String locale; // 'en', 'es', 'fr', 'de', 'ar'
  final String variant; // 'brief' | 'detailed'
  final bool enabled;
  final String bodyPreview;
  final DateTime updatedAt;

  const TemplateMetadata({
    required this.id,
    required this.type,
    required this.locale,
    required this.variant,
    required this.enabled,
    required this.bodyPreview,
    required this.updatedAt,
  });

  factory TemplateMetadata.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final body = data['bodyTemplate'] as String? ?? '';
    return TemplateMetadata(
      id: doc.id,
      type: data['type'] as String? ?? 'sms',
      locale: data['locale'] as String? ?? 'en',
      variant: data['variant'] as String? ?? 'brief',
      enabled: data['enabled'] as bool? ?? true,
      bodyPreview: body.length > 50 ? '${body.substring(0, 50)}...' : body,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class TemplateDocument {
  final String id;
  final String type; // 'sms' | 'email' | 'push'
  final String locale;
  final String variant;
  final String? subjectTemplate;
  final String bodyTemplate;
  final String? titleTemplate;
  final bool enabled;
  final DateTime updatedAt;

  const TemplateDocument({
    required this.id,
    required this.type,
    required this.locale,
    required this.variant,
    this.subjectTemplate,
    required this.bodyTemplate,
    this.titleTemplate,
    required this.enabled,
    required this.updatedAt,
  });

  factory TemplateDocument.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return TemplateDocument(
      id: doc.id,
      type: data['type'] as String? ?? 'sms',
      locale: data['locale'] as String? ?? 'en',
      variant: data['variant'] as String? ?? 'brief',
      subjectTemplate: data['subjectTemplate'] as String?,
      bodyTemplate: data['bodyTemplate'] as String? ?? '',
      titleTemplate: data['titleTemplate'] as String?,
      enabled: data['enabled'] as bool? ?? true,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'type': type,
      'locale': locale,
      'variant': variant,
      if (subjectTemplate != null) 'subjectTemplate': subjectTemplate,
      'bodyTemplate': bodyTemplate,
      if (titleTemplate != null) 'titleTemplate': titleTemplate,
      'enabled': enabled,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

class TemplatesAdminRepository {
  final FirebaseFirestore _firestore;
  final TemplateAuditLogRepository _auditLogRepo;

  TemplatesAdminRepository({
    FirebaseFirestore? firestore,
    TemplateAuditLogRepository? auditLogRepo,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auditLogRepo = auditLogRepo ?? TemplateAuditLogRepository(firestore: firestore);

  Future<String> getAdminRole(String uid) async {
    if (uid.isEmpty) return '';
    try {
      final doc = await _firestore.collection('admins').doc(uid).get();
      if (doc.exists && doc.data()?['role'] != null) {
        return doc.data()!['role'] as String;
      }
    } catch (_) {}
    return '';
  }

  Future<List<TemplateMetadata>> listTemplates({String? userRole}) async {
    final snapshot = await _firestore
        .collection('templates')
        .orderBy('locale')
        .orderBy('type')
        .get();

    final all = snapshot.docs.map((doc) => TemplateMetadata.fromFirestore(doc)).toList();

    if (userRole == null || userRole.isEmpty || AdminRoleHelper.isGlobalAdmin(userRole)) {
      return all;
    }

    final allowedLocale = AdminRoleHelper.getLocaleForRole(userRole);
    if (allowedLocale != null) {
      return all.where((t) => t.locale.toLowerCase() == allowedLocale.toLowerCase()).toList();
    }

    return [];
  }

  Future<TemplateDocument?> getTemplate(String docId) async {
    final doc = await _firestore.collection('templates').doc(docId).get();
    if (!doc.exists) return null;
    return TemplateDocument.fromFirestore(doc);
  }

  Future<void> saveTemplate(
    TemplateDocument template,
    String adminUid,
    String adminRole, {
    bool isRestoration = false,
    String? restoredFromAuditLogId,
  }) async {
    if (!AdminRoleHelper.canEditLocale(adminRole, template.locale)) {
      throw Exception('Permission denied: Your role ($adminRole) cannot edit templates for locale "${template.locale}".');
    }

    final docRef = template.id.isEmpty
        ? _firestore.collection('templates').doc()
        : _firestore.collection('templates').doc(template.id);

    final isCreate = template.id.isEmpty;
    Map<String, dynamic>? beforeMap;

    if (!isCreate) {
      final existingDoc = await getTemplate(template.id);
      if (existingDoc != null) {
        beforeMap = existingDoc.toFirestore();
      }
    }

    final templateId = docRef.id;
    final afterMap = template.toFirestore();
    if (restoredFromAuditLogId != null) {
      afterMap['restoredFromAuditLogId'] = restoredFromAuditLogId;
    }

    await docRef.set(template.toFirestore(), SetOptions(merge: true));

    final actionName = isRestoration ? 'restore' : (isCreate ? 'create' : 'update');

    await _auditLogRepo.logChange(
      templateId: templateId,
      changedByUid: adminUid,
      action: actionName,
      before: beforeMap,
      after: afterMap,
    );
  }

  Future<void> toggleEnabled(String docId, bool enabled, String adminUid, String adminRole) async {
    final existingDoc = await getTemplate(docId);
    if (existingDoc == null) throw Exception('Template not found');

    if (!AdminRoleHelper.canToggleEnabled(adminRole, existingDoc.locale)) {
      throw Exception('Permission denied: Your role ($adminRole) cannot toggle status for locale "${existingDoc.locale}".');
    }

    final beforeMap = {'enabled': existingDoc.enabled};
    final afterMap = {'enabled': enabled};

    await _firestore.collection('templates').doc(docId).update({
      'enabled': enabled,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _auditLogRepo.logChange(
      templateId: docId,
      changedByUid: adminUid,
      action: 'toggle_enabled',
      before: beforeMap,
      after: afterMap,
    );
  }
}
