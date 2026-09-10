class PhoneNormalizer {
  String normalize(String rawPhone, [String? countryCode]) {
    if (rawPhone.trim().isEmpty) return '';
    
    // Remove all non-numeric characters except the leading '+'
    String cleaned = rawPhone.replaceAll(RegExp(r'[^\d+]'), '');
    
    if (cleaned.startsWith('+')) {
      return cleaned;
    }
    
    final code = (countryCode != null && countryCode.trim().isNotEmpty) ? countryCode.trim() : '+1';
    final prefix = code.startsWith('+') ? code : '+$code';
    
    return '$prefix$cleaned';
  }

  bool isValidE164(String phone) {
    final e164Regex = RegExp(r'^\+[1-9]\d{1,14}$');
    return e164Regex.hasMatch(phone);
  }
}
