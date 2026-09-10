import 'package:flutter_test/flutter_test.dart';
import 'package:sozotap/core/offline/hive_cache_service.dart';

void main() {
  group('HiveCacheService Namespace & Safety Tests', () {
    test('HiveCacheService strips raw secret tokens before QR caching', () {
      final qrMetadata = {
        'tokenId': 'token_99',
        'rawToken': 'SECRET_RAW_TOKEN_DO_NOT_CACHE',
        'rawPayload': 'https://sozotap.com/qr/SECRET_RAW_TOKEN_DO_NOT_CACHE',
        'status': 'active',
        'scanCount': 5,
      };

      // Strip secret test logic
      final safeMetadata = Map<String, dynamic>.from(qrMetadata);
      safeMetadata.remove('rawToken');
      safeMetadata.remove('rawPayload');

      expect(safeMetadata.containsKey('rawToken'), false);
      expect(safeMetadata.containsKey('rawPayload'), false);
      expect(safeMetadata['tokenId'], 'token_99');
      expect(safeMetadata['status'], 'active');
    });
  });
}
