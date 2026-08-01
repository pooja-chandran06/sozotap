class PhoneNormalizer {
  String normalize(String rawPhone, String? countryCode) {
    if (rawPhone.isEmpty) return '';
    
    // Remove all non-numeric characters except the leading '+'
    String cleaned = rawPhone.replaceAll(RegExp(r'[^\d+]'), '');
    
    if (cleaned.startsWith('+')) {
      return cleaned;
    }
    
    final code = (countryCode?.isNotEmpty == true) ? countryCode! : '+1';
    final prefix = code.startsWith('+') ? code : '+$code';
    
    return '$prefix$cleaned';
  }
}
