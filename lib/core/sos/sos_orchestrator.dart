import '../../medical_profile/domain/models/medical_profile.dart';
import '../../emergency_contacts/domain/models/emergency_contact.dart';
import '../../utils/logger.dart';
import '../templates/template_service.dart';
import 'sos_logger.dart';
import 'dispatch_service.dart';

class SosOrchestrator {
  final TemplateService _templateService;
  final SosLogger _sosLogger;
  final DispatchService _smsDispatchService;
  final DispatchService _emailDispatchService;
  final DispatchService _pushDispatchService;

  SosOrchestrator(
    this._templateService,
    this._sosLogger,
    this._smsDispatchService,
    this._emailDispatchService,
    this._pushDispatchService,
  );

  /// Triggers the SOS sequence and returns a list of dispatched message IDs for tracking
  Future<List<String>> triggerSos({
    required MedicalProfile profile,
    required List<EmergencyContact> contacts,
    required NotificationChannel channel,
    String locale = 'en',
    String templateVariant = 'brief', // 'brief' | 'detailed'
    Map<String, dynamic>? dynamicVars,
  }) async {
    AppLogger.w('Initiating SOS sequence for user ${profile.uid} via ${channel.name} [Locale: $locale, Variant: $templateVariant]');
    
    // Preload templates asynchronously if Firestore backend is enabled
    await _templateService.preloadFirestoreTemplates(locale, templateVariant);

    final List<String> messageIds = [];

    if (channel == NotificationChannel.sms || channel == NotificationChannel.all || channel == NotificationChannel.both) {
      final smsContacts = contacts.where((c) => c.canSms).toList();
      final smsIds = await _dispatchSms(profile, smsContacts, locale, templateVariant, dynamicVars);
      messageIds.addAll(smsIds);
    }

    if (channel == NotificationChannel.email || channel == NotificationChannel.all || channel == NotificationChannel.both) {
      final emailContacts = contacts.where((c) => c.canSms).toList(); 
      final emailIds = await _dispatchEmail(profile, emailContacts, locale, templateVariant, dynamicVars);
      messageIds.addAll(emailIds);
    }

    if (channel == NotificationChannel.push || channel == NotificationChannel.all) {
      final appUserContacts = contacts.toList(); 
      final pushIds = await _dispatchPush(profile, appUserContacts, locale, templateVariant, dynamicVars);
      messageIds.addAll(pushIds);
    }

    if (channel == NotificationChannel.apiDispatch || channel == NotificationChannel.all || channel == NotificationChannel.both) {
      await _dispatchToApi(dynamicVars ?? {});
    }

    await _sosLogger.logSosEvent(profile.uid, contacts, SosChannel.both);
    return messageIds;
  }

  Future<List<String>> _dispatchSms(
    MedicalProfile profile,
    List<EmergencyContact> contacts,
    String locale,
    String templateVariant,
    Map<String, dynamic>? vars,
  ) async {
    List<String> ids = [];
    for (final contact in contacts) {
      try {
        final body = _templateService.buildSmsBody(
          profile: profile,
          contact: contact,
          locale: locale,
          templateVariant: templateVariant,
          dynamicVars: vars,
        );
        final id = await _smsDispatchService.sendNotification(
          to: contact.phoneNumber,
          channel: NotificationChannel.sms,
          body: body,
          metadata: {'contactId': contact.id, 'userId': profile.uid},
        );
        ids.add(id);
      } catch (e) {
        AppLogger.e('Failed to orchestrate SMS for ${contact.phoneNumber}', e, null);
      }
    }
    return ids;
  }

  Future<List<String>> _dispatchEmail(
    MedicalProfile profile,
    List<EmergencyContact> contacts,
    String locale,
    String templateVariant,
    Map<String, dynamic>? vars,
  ) async {
    List<String> ids = [];
    for (final contact in contacts) {
      try {
        final body = _templateService.buildHtmlEmail(
          profile: profile,
          contact: contact,
          locale: locale,
          templateVariant: templateVariant,
          dynamicVars: vars,
        );
        final fakeEmail = '${contact.name.replaceAll(' ', '').toLowerCase()}@example.com';
        final id = await _emailDispatchService.sendNotification(
          to: fakeEmail, 
          channel: NotificationChannel.email,
          subject: 'EMERGENCY SOS from ${profile.fullName}',
          body: body,
          metadata: {'contactId': contact.id, 'userId': profile.uid},
        );
        ids.add(id);
      } catch (e) {
        AppLogger.e('Failed to orchestrate Email for ${contact.name}', e, null);
      }
    }
    return ids;
  }

  Future<List<String>> _dispatchPush(
    MedicalProfile profile,
    List<EmergencyContact> contacts,
    String locale,
    String templateVariant,
    Map<String, dynamic>? vars,
  ) async {
    List<String> ids = [];
    for (final contact in contacts) {
      try {
        final pushTemplate = _templateService.buildPushTemplate(
          profile: profile,
          contact: contact,
          locale: locale,
          templateVariant: templateVariant,
          dynamicVars: vars,
        );
        final id = await _pushDispatchService.sendNotification(
          to: contact.userId.isNotEmpty ? contact.userId : contact.id,
          channel: NotificationChannel.push,
          subject: pushTemplate.title,
          body: pushTemplate.body,
          metadata: pushTemplate.data,
        );
        ids.add(id);
      } catch (e) {
        AppLogger.e('Failed to orchestrate Push for ${contact.name}', e, null);
      }
    }
    return ids;
  }

  Future<void> _dispatchToApi(Map<String, dynamic> payload) async {
    AppLogger.i('[STUB] Dispatching to Emergency API with payload: $payload');
  }
}
