class AppUser {
  final String id;
  final String email;
  final String displayName;
  final bool isEmailVerified;

  const AppUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.isEmailVerified,
  });

  AppUser copyWith({
    String? id,
    String? email,
    String? displayName,
    bool? isEmailVerified,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
    );
  }
}
