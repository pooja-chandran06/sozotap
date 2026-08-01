import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/medical_profile.dart';

class MedicalProfileCacheService {
  final SharedPreferences _prefs;
  
  MedicalProfileCacheService(this._prefs);

  Future<void> cacheProfile(MedicalProfile profile) async {
    await _prefs.setString('medical_profile_${profile.uid}', profile.toJson());
  }

  MedicalProfile? getCachedProfile(String uid) {
    final data = _prefs.getString('medical_profile_$uid');
    if (data != null) {
      return MedicalProfile.fromJson(data);
    }
    return null;
  }
}
