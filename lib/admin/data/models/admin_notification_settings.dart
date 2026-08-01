import 'package:cloud_firestore/cloud_firestore.dart';

class AdminNotificationSettings {
  final String uid;
  final bool notifyOnTemplateChange;
  final String preferredChannel; // 'email' | 'slack' | 'push' | 'both' | 'none'
  final String? emailOverride;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AdminNotificationSettings({
    required this.uid,
    this.notifyOnTemplateChange = true,
    this.preferredChannel = 'email',
    this.emailOverride,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AdminNotificationSettings.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return AdminNotificationSettings(
      uid: doc.id,
      notifyOnTemplateChange: data['notifyOnTemplateChange'] as bool? ?? true,
      preferredChannel: data['preferredChannel'] as String? ?? 'email',
      emailOverride: data['emailOverride'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'notifyOnTemplateChange': notifyOnTemplateChange,
      'preferredChannel': preferredChannel,
      if (emailOverride != null && emailOverride!.isNotEmpty) 'emailOverride': emailOverride,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  AdminNotificationSettings copyWith({
    String? uid,
    bool? notifyOnTemplateChange,
    String? preferredChannel,
    String? emailOverride,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AdminNotificationSettings(
      uid: uid ?? this.uid,
      notifyOnTemplateChange: notifyOnTemplateChange ?? this.notifyOnTemplateChange,
      preferredChannel: preferredChannel ?? this.preferredChannel,
      emailOverride: emailOverride ?? this.emailOverride,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
