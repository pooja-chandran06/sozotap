class AdminRoleHelper {
  static const String roleGlobalAdmin = 'global_admin';
  static const String prefixLocaleEditor = 'locale_editor_';
  static const String prefixLocaleAdmin = 'locale_admin_';

  static bool isGlobalAdmin(String role) {
    return role.trim() == roleGlobalAdmin;
  }

  static bool canEditAllTemplates(String role) {
    return isGlobalAdmin(role);
  }

  /// Extracts the target locale if the role is locale-specific (e.g. locale_editor_es -> es), else returns null for global_admin
  static String? getLocaleForRole(String role) {
    final clean = role.trim();
    if (clean.startsWith(prefixLocaleEditor)) {
      return clean.substring(prefixLocaleEditor.length);
    }
    if (clean.startsWith(prefixLocaleAdmin)) {
      return clean.substring(prefixLocaleAdmin.length);
    }
    return null;
  }

  /// Checks if the role allows editing templates for a given locale
  static bool canEditLocale(String role, String templateLocale) {
    if (isGlobalAdmin(role)) return true;
    final allowedLocale = getLocaleForRole(role);
    return allowedLocale != null && allowedLocale.toLowerCase() == templateLocale.toLowerCase();
  }

  /// Checks if the role allows enabling/disabling templates for a given locale
  static bool canToggleEnabled(String role, String templateLocale) {
    if (isGlobalAdmin(role)) return true;
    final clean = role.trim();
    if (clean.startsWith(prefixLocaleAdmin)) {
      final allowedLocale = clean.substring(prefixLocaleAdmin.length);
      return allowedLocale.toLowerCase() == templateLocale.toLowerCase();
    }
    return false;
  }
}
