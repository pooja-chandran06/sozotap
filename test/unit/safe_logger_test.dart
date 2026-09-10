import 'package:flutter_test/flutter_test.dart';
import 'package:sozotap/core/logging/safe_logger.dart';

void main() {
  group('SafeLogger Redaction Tests', () {
    test('redacts email addresses accurately', () {
      expect(SafeLogger.redactEmail('john.doe@example.com'), 'j***e@example.com');
      expect(SafeLogger.redactEmail('ab@test.org'), 'a***@test.org');
      expect(SafeLogger.redactEmail('invalid_email'), '[REDACTED_EMAIL]');
    });

    test('redacts E.164 phone numbers accurately', () {
      expect(SafeLogger.redactPhone('+14155552671'), '+14****2671');
      expect(SafeLogger.redactPhone('123'), '[REDACTED_PHONE]');
    });

    test('redacts composite log messages containing PII and medical keywords', () {
      const logWithPii = 'User john.doe@example.com with phone +14155552671 located at 37.7749,-122.4194 blood_type=O+';
      final redacted = SafeLogger.redactMessage(logWithPii);

      expect(redacted.contains('john.doe@example.com'), false);
      expect(redacted.contains('j***e@example.com'), true);
      expect(redacted.contains('+14155552671'), false);
      expect(redacted.contains('+14****2671'), true);
      expect(redacted.contains('37.7749,-122.4194'), false);
      expect(redacted.contains('[REDACTED_COORDINATES]'), true);
      expect(redacted.contains('blood_type=O+'), false);
      expect(redacted.contains('blood_type=[REDACTED_MEDICAL_DATA]'), true);
    });

    test('redacts authentication and bearer tokens', () {
      const logWithToken = 'Authorization Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.e30.secret';
      final redacted = SafeLogger.redactMessage(logWithToken);

      expect(redacted.contains('eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9'), false);
      expect(redacted.contains('[REDACTED_TOKEN]'), true);
    });
  });
}
