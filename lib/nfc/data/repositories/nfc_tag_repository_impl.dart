import 'dart:async';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:sozotap/core/logging/safe_logger.dart';
import 'package:sozotap/core/errors/app_exception.dart';
import 'package:sozotap/nfc/domain/repositories/nfc_tag_repository.dart';

class NfcTagRepositoryImpl implements NfcTagRepository {
  static const String _baseUrl = 'https://vitanexus.web.app/scan?token=';

  @override
  Future<bool> isNfcAvailable() async {
    try {
      return await NfcManager.instance.isAvailable();
    } catch (e) {
      SafeLogger.warn('Error checking NFC availability: $e');
      return false;
    }
  }

  @override
  Future<void> writeEmergencyTokenTag(String opaqueToken) async {
    final isAvail = await isNfcAvailable();
    if (!isAvail) {
      throw const ValidationException('NFC is not supported or enabled on this device.');
    }

    final completer = Completer<void>();
    final targetUrl = '$_baseUrl$opaqueToken';

    NfcManager.instance.startSession(
      onDiscovered: (NfcTag tag) async {
        try {
          final ndef = Ndef.from(tag);
          if (ndef == null) {
            NfcManager.instance.stopSession(errorMessage: 'Tag does not support NDEF.');
            completer.completeError(const ValidationException('Tag is not NDEF compatible.'));
            return;
          }

          if (!ndef.isWritable) {
            NfcManager.instance.stopSession(errorMessage: 'Tag is read-only.');
            completer.completeError(const ValidationException('Tag is read-only and cannot be written.'));
            return;
          }

          final UriRecord uriRecord = UriRecord.fromUri(Uri.parse(targetUrl));
          final NdefMessage message = NdefMessage([uriRecord]);

          if (ndef.maxSize < message.byteLength) {
            NfcManager.instance.stopSession(errorMessage: 'Tag capacity exceeded.');
            completer.completeError(const ValidationException('Tag capacity is too small for payload.'));
            return;
          }

          await ndef.write(message);
          NfcManager.instance.stopSession();
          SafeLogger.info('SOZOTAP NFC Tag written successfully');
          completer.complete();
        } catch (e) {
          NfcManager.instance.stopSession(errorMessage: 'Write failed: $e');
          completer.completeError(ValidationException('NFC write error: $e'));
        }
      },
      onError: (NfcError error) async {
        completer.completeError(ValidationException('NFC session error: ${error.message}'));
      },
    );

    return completer.future;
  }

  @override
  Future<String?> readEmergencyTokenTag() async {
    final isAvail = await isNfcAvailable();
    if (!isAvail) {
      throw const ValidationException('NFC is not supported or enabled on this device.');
    }

    final completer = Completer<String?>();

    NfcManager.instance.startSession(
      onDiscovered: (NfcTag tag) async {
        try {
          final ndef = Ndef.from(tag);
          if (ndef == null) {
            NfcManager.instance.stopSession();
            completer.complete(null);
            return;
          }

          final NdefMessage? cachedMessage = ndef.cachedMessage;
          if (cachedMessage == null || cachedMessage.records.isEmpty) {
            NfcManager.instance.stopSession();
            completer.complete(null);
            return;
          }

          for (final record in cachedMessage.records) {
            final payload = String.fromCharCodes(record.payload);
            if (payload.contains(_baseUrl)) {
              final token = payload.substring(payload.indexOf(_baseUrl) + _baseUrl.length).trim();
              NfcManager.instance.stopSession();
              completer.complete(token);
              return;
            }
          }

          NfcManager.instance.stopSession();
          completer.complete(null);
        } catch (e) {
          NfcManager.instance.stopSession();
          completer.completeError(ValidationException('Failed to read NFC tag: $e'));
        }
      },
      onError: (NfcError error) async {
        completer.completeError(ValidationException('NFC read error: ${error.message}'));
      },
    );

    return completer.future;
  }

  @override
  Future<void> stopSession() async {
    try {
      await NfcManager.instance.stopSession();
    } catch (_) {}
  }
}
