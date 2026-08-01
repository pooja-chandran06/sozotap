class UserSettings {
  final String userId;
  final String templateVariant; // 'brief' | 'detailed'
  final String preferredLocale; // 'en' | 'es' | 'fr'
  final bool enablePushNotifications;
  final bool shareLiveLocation;

  const UserSettings({
    required this.userId,
    this.templateVariant = 'brief',
    this.preferredLocale = 'en',
    this.enablePushNotifications = true,
    this.shareLiveLocation = true,
  });

  UserSettings copyWith({
    String? userId,
    String? templateVariant,
    String? preferredLocale,
    bool? enablePushNotifications,
    bool? shareLiveLocation,
  }) {
    return UserSettings(
      userId: userId ?? this.userId,
      templateVariant: templateVariant ?? this.templateVariant,
      preferredLocale: preferredLocale ?? this.preferredLocale,
      enablePushNotifications: enablePushNotifications ?? this.enablePushNotifications,
      shareLiveLocation: shareLiveLocation ?? this.shareLiveLocation,
    );
  }

  factory UserSettings.fromJson(Map<String, dynamic> json, String userId) {
    return UserSettings(
      userId: userId,
      templateVariant: json['templateVariant'] as String? ?? 'brief',
      preferredLocale: json['preferredLocale'] as String? ?? 'en',
      enablePushNotifications: json['enablePushNotifications'] as bool? ?? true,
      shareLiveLocation: json['shareLiveLocation'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'templateVariant': templateVariant,
      'preferredLocale': preferredLocale,
      'enablePushNotifications': enablePushNotifications,
      'shareLiveLocation': shareLiveLocation,
    };
  }
}
