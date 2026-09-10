abstract class NfcTagRepository {
  /// Check if NFC hardware is available on the device
  Future<bool> isNfcAvailable();

  /// Write an opaque SOZOTAP emergency token to an NDEF tag.
  /// Formats the tag with URI record: https://vitanexus.web.app/scan?token=<opaqueToken>
  /// Never writes PII or raw medical data.
  Future<void> writeEmergencyTokenTag(String opaqueToken);

  /// Read and parse an NDEF tag to retrieve the SOZOTAP opaque token if present.
  Future<String?> readEmergencyTokenTag();

  /// Stop any active NFC session
  Future<void> stopSession();
}
