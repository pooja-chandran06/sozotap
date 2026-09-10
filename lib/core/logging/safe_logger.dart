import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Centralized safe logging utility for SOZOTAP.
/// Automatically redacts PII (emails, phone numbers, auth tokens, GPS coordinates, medical records).
class SafeLogger {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 80,
      colors: true,
      printEmojis: true,
      printTime: true,
    ),
  );

  /// Redact email addresses: e.g. john.doe@example.com -> j***e@example.com
  static String redactEmail(String email) {
    final emailRegExp = RegExp(r'^([^@]+)@(.+)$');
    final match = emailRegExp.firstMatch(email.trim());
    if (match == null) return '[REDACTED_EMAIL]';
    final user = match.group(1)!;
    final domain = match.group(2)!;
    if (user.length <= 2) {
      return '${user[0]}***@$domain';
    }
    return '${user[0]}***${user[user.length - 1]}@$domain';
  }

  /// Redact phone numbers: e.g. +14155552671 -> +14****2671
  static String redactPhone(String phone) {
    final clean = phone.trim();
    if (clean.length < 6) return '[REDACTED_PHONE]';
    final prefix = clean.substring(0, 3);
    final suffix = clean.substring(clean.length - 4);
    return '$prefix****$suffix';
  }

  /// Redact arbitrary strings containing PII or medical data
  static String redactMessage(String message) {
    var sanitized = message;

    // Redact Emails
    final emailPattern = RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b');
    sanitized = sanitized.replaceAllMapped(emailPattern, (m) => redactEmail(m.group(0)!));

    // Redact E.164 Phone numbers
    final phonePattern = RegExp(r'\+?[0-9]{10,15}');
    sanitized = sanitized.replaceAllMapped(phonePattern, (m) => redactPhone(m.group(0)!));

    // Redact Lat/Lng Coordinates (e.g., 37.7749,-122.4194)
    final coordPattern = RegExp(r'-?\d{1,3}\.\d{4,},\s*-?\d{1,3}\.\d{4,}');
    sanitized = sanitized.replaceAll(coordPattern, '[REDACTED_COORDINATES]');

    // Redact Bearer / FCM / QR Tokens
    final tokenPattern = RegExp(r'\b(Bearer\s+|token=|[a-f0-9]{32,}|eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+)\b', caseSensitive: false);
    sanitized = sanitized.replaceAll(tokenPattern, '[REDACTED_TOKEN]');

    // Redact specific medical field keywords if logged together with data
    final medicalKeywordPattern = RegExp(r'(blood_type|allergies|medications|conditions|medical_notes)=([^,\s]+)', caseSensitive: false);
    sanitized = sanitized.replaceAllMapped(medicalKeywordPattern, (m) => '${m.group(1)}=[REDACTED_MEDICAL_DATA]');

    return sanitized;
  }

  static void info(String message) {
    if (kReleaseMode) return;
    _logger.i(redactMessage(message));
  }

  static void debug(String message) {
    if (kReleaseMode) return;
    _logger.d(redactMessage(message));
  }

  static void warn(String message, {Object? error, StackTrace? stackTrace}) {
    _logger.w(redactMessage(message), error: error, stackTrace: stackTrace);
  }

  static void error(String message, {Object? error, StackTrace? stackTrace}) {
    _logger.e(redactMessage(message), error: error, stackTrace: stackTrace);
  }
}
