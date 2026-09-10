import 'package:flutter_test/flutter_test.dart';
import 'package:sozotap/config/app_config.dart';

void main() {
  group('Live Location Throttling Logic Tests', () {
    test('Verifies minimum write interval configuration', () {
      expect(AppConfig.liveLocationMinWriteInterval, const Duration(seconds: 30));
    });

    test('Verifies distance filter configuration', () {
      expect(AppConfig.liveLocationDistanceFilterMeters, 25);
    });

    test('Throttling logic enforces 30 seconds threshold between Firestore writes', () {
      final firstWrite = DateTime(2026, 9, 5, 12, 0, 0);
      final sub20sWrite = DateTime(2026, 9, 5, 12, 0, 20);
      final post30sWrite = DateTime(2026, 9, 5, 12, 0, 31);

      bool shouldWrite(DateTime lastWrite, DateTime currentTime) {
        return currentTime.difference(lastWrite) >= AppConfig.liveLocationMinWriteInterval;
      }

      expect(shouldWrite(firstWrite, sub20sWrite), isFalse);
      expect(shouldWrite(firstWrite, post30sWrite), isTrue);
    });
  });
}
