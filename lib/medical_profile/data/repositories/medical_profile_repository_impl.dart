import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/medical_profile.dart';

class MedicalProfileCacheService {
  final SharedPreferences _prefs;

  MedicalProfileCacheService(this._prefs);

  Future<void> cacheProfile(MedicalProfile profile) async {
    final key = 'medical_profile_${profile.uid}';

    try {
      final json = profile.toJson();

      await _prefs
          .setString(key, json)
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      // Local cache is optional.
      // Firestore remains the main source of truth.
    }
  }

  MedicalProfile? getCachedProfile(String uid) {
    try {
      final data = _prefs.getString('medical_profile_$uid');

      if (data == null || data.isEmpty) {
        return null;
      }

      return MedicalProfile.fromJson(data);
    } catch (_) {
      return null;
    }
  }
}