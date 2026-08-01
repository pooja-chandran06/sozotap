import 'package:cloud_firestore/cloud_firestore.dart';
import '../../medical_profile/domain/models/medical_profile.dart';
import '../../emergency_contacts/domain/models/emergency_contact.dart';
import '../../utils/logger.dart';
import 'push_template.dart';

/// Extensible Template Service for SOZOTAP.
/// 
/// HOW TO ADD A NEW LOCALE (e.g. "de", "ar", "hi", "ja"):
/// 1. Add the 2-letter ISO code to [supportedLocales] array.
/// 2. Add entries in [_localTemplates] map for sms_LOCALE_brief, sms_LOCALE_detailed, 
///    email_LOCALE_brief, email_LOCALE_detailed, push_title_LOCALE_brief, push_body_LOCALE_brief, etc.
/// 3. (Optional) Seed the Firestore "templates" collection with matching documents.
class TemplateService {
  final FirebaseFirestore _firestore;
  final Map<String, Map<String, dynamic>> _templateCache = {};

  TemplateService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Central configuration of supported locales
  static const List<String> supportedLocales = ['en', 'es', 'fr', 'de', 'ar'];

  /// Built-in local fallbacks map keyed by `type_locale_variant`
  static const Map<String, String> _localTemplates = {
    // English (en)
    'sms_en_brief': "EMERGENCY SOS: {{patientName}} needs help! Blood: {{bloodGroup}}. Location: {{gpsUrl}}",
    'sms_en_detailed': "EMERGENCY SOS: {{patientName}} needs urgent assistance! Blood: {{bloodGroup}} | Conditions: {{conditions}} | Allergies: {{allergies}} | Meds: {{medications}} | Doctor: {{doctorName}} | Hospital: {{hospitalName}} | Location: {{gpsUrl}} | Time: {{timestamp}}",
    'email_en_brief': "<h2>EMERGENCY SOS ALERT</h2><p><b>{{patientName}}</b> needs help immediately!</p><p><b>Blood Group:</b> {{bloodGroup}}</p><p><b>Live Location:</b> <a href=\"{{gpsUrl}}\">{{gpsUrl}}</a></p><p><small>Timestamp: {{timestamp}}</small></p>",
    'email_en_detailed': "<div style=\"font-family: Arial, sans-serif; padding: 20px; border: 2px solid #E53935;\"><h1 style=\"color: #E53935;\">🚨 CRITICAL MEDICAL EMERGENCY SOS</h1><p><b>{{patientName}}</b> has triggered an emergency alert.</p><hr/><h2>Patient Dossier</h2><ul><li><b>Blood Group:</b> {{bloodGroup}}</li><li><b>Conditions:</b> {{conditions}}</li><li><b>Allergies:</b> {{allergies}}</li><li><b>Medications:</b> {{medications}}</li></ul><h2>Medical Provider</h2><p>Doctor: {{doctorName}} | Hospital: {{hospitalName}}</p><p>Location: <a href=\"{{gpsUrl}}\">{{gpsUrl}}</a></p></div>",
    'push_title_en_brief': "🚨 SOS from {{patientName}}!",
    'push_body_en_brief': "Emergency alert triggered. Tap to open tracking map.",
    'push_title_en_detailed': "🚨 CRITICAL SOS: {{patientName}} ({{bloodGroup}})",
    'push_body_en_detailed': "Conditions: {{conditions}}. Location updated. Tap to open live tracking map.",

    // Spanish (es)
    'sms_es_brief': "SOS DE EMERGENCIA: ¡{{patientName}} necesita ayuda! Sangre: {{bloodGroup}}. Ubicación: {{gpsUrl}}",
    'sms_es_detailed': "SOS DE EMERGENCIA: ¡{{patientName}} necesita asistencia urgente! Sangre: {{bloodGroup}} | Condiciones: {{conditions}} | Alergias: {{allergies}} | Meds: {{medications}} | Doctor: {{doctorName}} | Hospital: {{hospitalName}} | Ubicación: {{gpsUrl}} | Hora: {{timestamp}}",
    'email_es_brief': "<h2>ALERTA SOS DE EMERGENCIA</h2><p>¡<b>{{patientName}}</b> necesita ayuda inmediatamente!</p><p><b>Grupo Sanguíneo:</b> {{bloodGroup}}</p><p><b>Ubicación:</b> <a href=\"{{gpsUrl}}\">{{gpsUrl}}</a></p><p><small>Hora: {{timestamp}}</small></p>",
    'email_es_detailed': "<div style=\"font-family: Arial, sans-serif; padding: 20px; border: 2px solid #E53935;\"><h1 style=\"color: #E53935;\">🚨 ALERTA SOS MÉDICA CRÍTICA</h1><p><b>{{patientName}}</b> ha activado una alerta de emergencia.</p><hr/><h2>Expediente del Paciente</h2><ul><li><b>Grupo Sanguíneo:</b> {{bloodGroup}}</li><li><b>Condiciones:</b> {{conditions}}</li><li><b>Alergias:</b> {{allergies}}</li><li><b>Medicamentos:</b> {{medications}}</li></ul><h2>Proveedor Médico</h2><p>Doctor: {{doctorName}} | Hospital: {{hospitalName}}</p><p>Ubicación: <a href=\"{{gpsUrl}}\">{{gpsUrl}}</a></p></div>",
    'push_title_es_brief': "🚨 ¡SOS de {{patientName}}!",
    'push_body_es_brief': "Alerta de emergencia activada. Toca para abrir mapa.",
    'push_title_es_detailed': "🚨 SOS CRÍTICO: {{patientName}} ({{bloodGroup}})",
    'push_body_es_detailed': "Condiciones: {{conditions}}. Ubicación actualizada. Toca para rastrear.",

    // French (fr)
    'sms_fr_brief': "SOS D'URGENCE: {{patientName}} a besoin d'aide! Sang: {{bloodGroup}}. Localisation: {{gpsUrl}}",
    'sms_fr_detailed': "SOS D'URGENCE: {{patientName}} a besoin d'une assistance urgente! Sang: {{bloodGroup}} | Pathologies: {{conditions}} | Allergies: {{allergies}} | Médicaments: {{medications}} | Médecin: {{doctorName}} | Hôpital: {{hospitalName}} | Localisation: {{gpsUrl}} | Heure: {{timestamp}}",
    'email_fr_brief': "<h2>ALERTE SOS D'URGENCE</h2><p><b>{{patientName}}</b> a besoin d'aide immédiatement!</p><p><b>Groupe Sanguin:</b> {{bloodGroup}}</p><p><b>Localisation:</b> <a href=\"{{gpsUrl}}\">{{gpsUrl}}</a></p><p><small>Heure: {{timestamp}}</small></p>",
    'email_fr_detailed': "<div style=\"font-family: Arial, sans-serif; padding: 20px; border: 2px solid #E53935;\"><h1 style=\"color: #E53935;\">🚨 ALERTE SOS MÉDICALE CRITIQUE</h1><p><b>{{patientName}}</b> a déclenché une alerte d'urgence.</p><hr/><h2>Dossier Patient</h2><ul><li><b>Groupe Sanguin:</b> {{bloodGroup}}</li><li><b>Pathologies:</b> {{conditions}}</li><li><b>Allergies:</b> {{allergies}}</li><li><b>Médicaments:</b> {{medications}}</li></ul><h2>Service Médical</h2><p>Médecin: {{doctorName}} | Hôpital: {{hospitalName}}</p><p>Localisation: <a href=\"{{gpsUrl}}\">{{gpsUrl}}</a></p></div>",
    'push_title_fr_brief': "🚨 SOS de {{patientName}}!",
    'push_body_fr_brief': "Alerte d'urgence déclenchée. Appuyez pour ouvrir la carte.",
    'push_title_fr_detailed': "🚨 SOS CRITIQUE: {{patientName}} ({{bloodGroup}})",
    'push_body_fr_detailed': "Pathologies: {{conditions}}. Localisation mise à jour. Appuyez pour suivre.",

    // German (de)
    'sms_de_brief': "NOTFALL-SOS: {{patientName}} braucht Hilfe! Blutgruppe: {{bloodGroup}}. Standort: {{gpsUrl}}",
    'sms_de_detailed': "NOTFALL-SOS: {{patientName}} benötigt dringend Hilfe! Blutgruppe: {{bloodGroup}} | Vorerkrankungen: {{conditions}} | Allergien: {{allergies}} | Medikamente: {{medications}} | Arzt: {{doctorName}} | Krankenhaus: {{hospitalName}} | Standort: {{gpsUrl}} | Zeit: {{timestamp}}",
    'email_de_brief': "<h2>NOTFALL-SOS ALERT</h2><p><b>{{patientName}}</b> braucht sofort Hilfe!</p><p><b>Blutgruppe:</b> {{bloodGroup}}</p><p><b>Standort:</b> <a href=\"{{gpsUrl}}\">{{gpsUrl}}</a></p><p><small>Zeitstempel: {{timestamp}}</small></p>",
    'email_de_detailed': "<div style=\"font-family: Arial, sans-serif; padding: 20px; border: 2px solid #E53935;\"><h1 style=\"color: #E53935;\">🚨 KRITISCHER MEDIZINISCHER NOTFALL-SOS</h1><p><b>{{patientName}}</b> hat einen Notfall-Notruf ausgelöst.</p><hr/><h2>Patientenakte</h2><ul><li><b>Blutgruppe:</b> {{bloodGroup}}</li><li><b>Vorerkrankungen:</b> {{conditions}}</li><li><b>Allergien:</b> {{allergies}}</li><li><b>Medikamente:</b> {{medications}}</li></ul><h2>Behandelnder Arzt & Krankenhaus</h2><p>Arzt: {{doctorName}} | Krankenhaus: {{hospitalName}}</p><p>Standort: <a href=\"{{gpsUrl}}\">{{gpsUrl}}</a></p></div>",
    'push_title_de_brief': "🚨 SOS von {{patientName}}!",
    'push_body_de_brief': "Notfall-Alarm ausgelöst. Tippen, um Karte zu öffnen.",
    'push_title_de_detailed': "🚨 KRITISCHES SOS: {{patientName}} ({{bloodGroup}})",
    'push_body_de_detailed': "Erkrankungen: {{conditions}}. Standort aktualisiert. Tippen zum Verfolgen.",

    // Arabic (ar)
    'sms_ar_brief': "طوارئ SOS: {{patientName}} يحتاج إلى المساعدة! فصيلة الدم: {{bloodGroup}}. الموقع: {{gpsUrl}}",
    'sms_ar_detailed': "طوارئ SOS: {{patientName}} بحاجة إلى مساعدة عاجلة! فصيلة الدم: {{bloodGroup}} | الحالات: {{conditions}} | الحساسية: {{allergies}} | الأدوية: {{medications}} | الطبيب: {{doctorName}} | المستشفى: {{hospitalName}} | الموقع: {{gpsUrl}} | الوقت: {{timestamp}}",
    'email_ar_brief': "<div dir=\"rtl\"><h2>تنبيه طوارئ SOS</h2><p><b>{{patientName}}</b> يحتاج إلى المساعدة فوراً!</p><p><b>فصيلة الدم:</b> {{bloodGroup}}</p><p><b>الموقع المباشر:</b> <a href=\"{{gpsUrl}}\">{{gpsUrl}}</a></p><p><small>الوقت: {{timestamp}}</small></p></div>",
    'email_ar_detailed': "<div dir=\"rtl\" style=\"font-family: Arial, sans-serif; padding: 20px; border: 2px solid #E53935;\"><h1 style=\"color: #E53935;\">🚨 تنبيه طوارئ طبية حاد SOS</h1><p>أطلق <b>{{patientName}}</b> نداء استغاثة طارئ.</p><hr/><h2>الملف الطبي للمريض</h2><ul><li><b>فصيلة الدم:</b> {{bloodGroup}}</li><li><b>الحالات الطبية:</b> {{conditions}}</li><li><b>الحساسية:</b> {{allergies}}</li><li><b>الأدوية الحالية:</b> {{medications}}</li></ul><h2>معلومات الطبيب والمستشفى</h2><p>الطبيب: {{doctorName}} | المستشفى المفصل: {{hospitalName}}</p><p>الموقع المباشر: <a href=\"{{gpsUrl}}\">{{gpsUrl}}</a></p></div>",
    'push_title_ar_brief': "🚨 نداء استغاثة SOS من {{patientName}}!",
    'push_body_ar_brief': "تم إطلاق تنبيه الطوارئ. اضغط لفتح خريطة التتبع.",
    'push_title_ar_detailed': "🚨 SOS حرج: {{patientName}} ({{bloodGroup}})",
    'push_body_ar_detailed': "الحالات: {{conditions}}. تم تحديث الموقع. اضغط للتتبع.",
  };

  String _getLocaleWithFallback(String locale) {
    final cleanLocale = locale.toLowerCase().trim();
    if (supportedLocales.contains(cleanLocale)) {
      return cleanLocale;
    }
    return 'en'; // Default fallback
  }

  String _resolve(String template, Map<String, dynamic> vars) {
    String resolved = template;
    vars.forEach((key, value) {
      resolved = resolved.replaceAll('{{$key}}', value?.toString() ?? '');
    });
    return resolved;
  }

  Map<String, dynamic> _buildVars(
    MedicalProfile profile,
    EmergencyContact contact,
    Map<String, dynamic>? dynamicVars,
  ) {
    return {
      'patientName': profile.fullName,
      'bloodGroup': profile.bloodGroup,
      'conditions': profile.medicalConditions,
      'allergies': profile.allergies,
      'medications': profile.currentMedications,
      'doctorName': profile.primaryDoctor,
      'hospitalName': profile.preferredHospital,
      'contactName': contact.name,
      'contactRelationship': contact.relationship.name,
      'gpsUrl': dynamicVars?['gpsLatitude'] != null && dynamicVars?['gpsLongitude'] != null
          ? 'https://maps.google.com/?q=${dynamicVars!['gpsLatitude']},${dynamicVars['gpsLongitude']}'
          : 'N/A',
      ...(dynamicVars ?? {}),
    };
  }

  Future<void> preloadFirestoreTemplates(String locale, String variant) async {
    final effectiveLocale = _getLocaleWithFallback(locale);
    final cacheKey = '${effectiveLocale}_$variant';

    if (_templateCache.containsKey(cacheKey)) return;

    try {
      final snapshot = await _firestore
          .collection('templates')
          .where('locale', isEqualTo: effectiveLocale)
          .where('variant', isEqualTo: variant)
          .where('enabled', isEqualTo: true)
          .get();

      final Map<String, dynamic> loaded = {};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final type = data['type'] as String?;
        if (type != null) {
          loaded[type] = data;
        }
      }

      _templateCache[cacheKey] = loaded;
    } catch (e) {
      AppLogger.w('Could not load Firestore templates for $cacheKey, using local assets.');
    }
  }

  String buildSmsBody({
    required MedicalProfile profile,
    required EmergencyContact contact,
    required String locale,
    String templateVariant = 'brief',
    Map<String, dynamic>? dynamicVars,
  }) {
    final effectiveLocale = _getLocaleWithFallback(locale);
    final vars = _buildVars(profile, contact, dynamicVars);
    
    // Check Firestore cache first
    final cached = _templateCache['${effectiveLocale}_$templateVariant']?['sms'];
    if (cached != null && cached['bodyTemplate'] != null) {
      return _resolve(cached['bodyTemplate'] as String, vars);
    }

    // Fallback to local template
    final key = 'sms_${effectiveLocale}_$templateVariant';
    final fallbackKey = 'sms_en_$templateVariant';
    final template = _localTemplates[key] ?? _localTemplates[fallbackKey] ?? _localTemplates['sms_en_detailed']!;

    return _resolve(template, vars);
  }

  String buildHtmlEmail({
    required MedicalProfile profile,
    required EmergencyContact contact,
    required String locale,
    String templateVariant = 'brief',
    Map<String, dynamic>? dynamicVars,
  }) {
    final effectiveLocale = _getLocaleWithFallback(locale);
    final vars = _buildVars(profile, contact, dynamicVars);

    // Check Firestore cache first
    final cached = _templateCache['${effectiveLocale}_$templateVariant']?['email'];
    if (cached != null && cached['bodyTemplate'] != null) {
      return _resolve(cached['bodyTemplate'] as String, vars);
    }

    // Fallback to local template
    final key = 'email_${effectiveLocale}_$templateVariant';
    final fallbackKey = 'email_en_$templateVariant';
    final template = _localTemplates[key] ?? _localTemplates[fallbackKey] ?? _localTemplates['email_en_detailed']!;

    String resolved = _resolve(template, vars);
    if (profile.photoUrl != null && profile.photoUrl!.isNotEmpty) {
      resolved = resolved.replaceFirst(
        '<h2>',
        '<div style="float: right;"><img src="${profile.photoUrl}" width="120" style="border-radius: 8px;"/></div><h2>',
      );
    }
    return resolved;
  }

  PushTemplate buildPushTemplate({
    required MedicalProfile profile,
    required EmergencyContact contact,
    required String locale,
    String templateVariant = 'brief',
    Map<String, dynamic>? dynamicVars,
  }) {
    final effectiveLocale = _getLocaleWithFallback(locale);
    final vars = _buildVars(profile, contact, dynamicVars);
    final sosId = vars['sosId'] ?? 'unknown';

    // Check Firestore cache first
    final cached = _templateCache['${effectiveLocale}_$templateVariant']?['push'];
    String? titleTmpl = cached?['titleTemplate'] as String?;
    String? bodyTmpl = cached?['bodyTemplate'] as String?;

    if (titleTmpl == null || bodyTmpl == null) {
      final titleKey = 'push_title_${effectiveLocale}_$templateVariant';
      final bodyKey = 'push_body_${effectiveLocale}_$templateVariant';

      titleTmpl = _localTemplates[titleKey] ?? _localTemplates['push_title_en_$templateVariant'] ?? _localTemplates['push_title_en_detailed']!;
      bodyTmpl = _localTemplates[bodyKey] ?? _localTemplates['push_body_en_$templateVariant'] ?? _localTemplates['push_body_en_detailed']!;
    }

    final title = _resolve(titleTmpl, vars);
    final body = _resolve(bodyTmpl, vars);

    return PushTemplate(
      title: title,
      body: body,
      data: {
        'type': 'sos_alert',
        'userId': vars['userId'] ?? '',
        'contactId': contact.id,
        'sosId': sosId,
        'actionUrl': 'sozotap://sos/details/$sosId',
        'timestamp': vars['timestamp'] ?? DateTime.now().toIso8601String(),
        if (vars['gpsLatitude'] != null) 'lat': vars['gpsLatitude'],
        if (vars['gpsLongitude'] != null) 'lng': vars['gpsLongitude'],
      },
    );
  }
}
