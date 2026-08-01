import '../../../core/security/phone_normalizer.dart';

class ValidatePhoneNumber {
  final PhoneNormalizer _phoneNormalizer;

  ValidatePhoneNumber(this._phoneNormalizer);

  bool execute(String phoneNumber, {String? countryCode}) {
    try {
      final normalized = _phoneNormalizer.normalize(phoneNumber, countryCode);
      return normalized.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}
