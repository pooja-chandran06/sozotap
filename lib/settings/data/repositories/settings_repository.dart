import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/privacy_settings_model.dart';

class SettingsRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final SharedPreferences _prefs;

  static const String keyThemeMode = 'app_theme_mode';
  static const String keyLanguageCode = 'app_language_code';
  static const String keyLastSynced = 'app_last_synced_at';

  SettingsRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    required SharedPreferences prefs,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _prefs = prefs;

  String? get _currentUserId => _auth.currentUser?.uid;

  // ---------------------------------------------------------------------------
  // THEME & LOCALE SETTINGS
  // ---------------------------------------------------------------------------

  String getThemeMode() {
    return _prefs.getString(keyThemeMode) ?? 'system';
  }

  Future<void> setThemeMode(String mode) async {
    await _prefs.setString(keyThemeMode, mode);
  }

  String getLanguageCode() {
    return _prefs.getString(keyLanguageCode) ?? 'en';
  }

  Future<void> setLanguageCode(String languageCode) async {
    await _prefs.setString(keyLanguageCode, languageCode);
  }

  DateTime? getLastSyncedAt() {
    final raw = _prefs.getString(keyLastSynced);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  Future<void> setLastSyncedAt(DateTime timestamp) async {
    await _prefs.setString(keyLastSynced, timestamp.toIso8601String());
  }

  // ---------------------------------------------------------------------------
  // PRIVACY SETTINGS
  // ---------------------------------------------------------------------------

  Stream<PrivacySettingsModel> getPrivacySettingsStream() {
    final uid = _currentUserId;
    if (uid == null) return Stream.value(PrivacySettingsModel.recommendedPreset());

    return _firestore
        .collection('users')
        .doc(uid)
        .collection('privacy_settings')
        .doc('settings')
        .snapshots()
        .map((snapshot) => PrivacySettingsModel.fromMap(snapshot.data()));
  }

  Future<void> updatePrivacySettings(PrivacySettingsModel settings) async {
    final uid = _currentUserId;
    if (uid == null) return;

    final batch = _firestore.batch();

    final privacyRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('privacy_settings')
        .doc('settings');

    final profileRef = _firestore.collection('medical_profiles').doc(uid);

    batch.set(privacyRef, settings.toMap(), SetOptions(merge: true));

    // Mirror authoritative consent flags to medical_profile so Cloud Function resolve Emergency QR reads flags cleanly
    batch.set(
      profileRef,
      {
        'emergencyAccessEnabled': settings.emergencyAccessEnabled,
        'shareNameInEmergency': settings.shareNameInEmergency,
        'sharePhotoInEmergency': settings.sharePhotoInEmergency,
        'shareBloodGroupInEmergency': settings.shareBloodGroupInEmergency,
        'shareAllergiesInEmergency': settings.shareAllergiesInEmergency,
        'shareMedicalConditionsInEmergency': settings.shareMedicalConditionsInEmergency,
        'shareMedicationsInEmergency': settings.shareMedicationsInEmergency,
        'shareImplantsInEmergency': settings.shareImplantsInEmergency,
        'shareDoctorHospitalInEmergency': settings.shareDoctorHospitalInEmergency,
        'shareEmergencyContactsInEmergency': settings.shareEmergencyContactsInEmergency,
        'shareHospitalDirectionsInEmergency': settings.shareHospitalDirectionsInEmergency,
        'shareEmergencyNotesInEmergency': settings.shareEmergencyNotesInEmergency,
        'lastEmergencyProfileUpdateAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    await batch.commit();
    await setLastSyncedAt(DateTime.now());
  }

  Future<void> resetPrivacyToRecommended() async {
    await updatePrivacySettings(PrivacySettingsModel.recommendedPreset());
  }
}
