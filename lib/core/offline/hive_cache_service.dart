import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logger/logger.dart';

class HiveCacheService {
  static final Logger _logger = Logger();
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    try {
      await Hive.initFlutter();
      _initialized = true;
      _logger.i('Hive cache service initialized successfully.');
    } catch (e) {
      _logger.e('Error initializing Hive cache service', error: e);
    }
  }

  // Helper box name generator for strict user isolation
  String _getUserBoxName(String uid, String boxType) {
    return 'user_${uid}_$boxType';
  }

  Future<void> cacheOwnerMedicalProfile(String uid, Map<String, dynamic> profileData) async {
    if (uid.isEmpty) return;
    try {
      final box = await Hive.openBox(_getUserBoxName(uid, 'profile'));
      await box.put('owner_profile', jsonEncode(profileData));
      await box.put('cached_at', DateTime.now().toIso8601String());
    } catch (e) {
      _logger.e('Failed to cache medical profile offline', error: e);
    }
  }

  Future<Map<String, dynamic>?> getCachedOwnerMedicalProfile(String uid) async {
    if (uid.isEmpty) return null;
    try {
      final box = await Hive.openBox(_getUserBoxName(uid, 'profile'));
      final raw = box.get('owner_profile');
      if (raw != null) {
        return jsonDecode(raw) as Map<String, dynamic>;
      }
    } catch (e) {
      _logger.e('Failed to read cached medical profile', error: e);
    }
    return null;
  }

  Future<void> cacheOwnerEmergencyContacts(String uid, List<Map<String, dynamic>> contactsData) async {
    if (uid.isEmpty) return;
    try {
      final box = await Hive.openBox(_getUserBoxName(uid, 'contacts'));
      await box.put('owner_contacts', jsonEncode(contactsData));
    } catch (e) {
      _logger.e('Failed to cache emergency contacts offline', error: e);
    }
  }

  Future<List<Map<String, dynamic>>?> getCachedOwnerEmergencyContacts(String uid) async {
    if (uid.isEmpty) return null;
    try {
      final box = await Hive.openBox(_getUserBoxName(uid, 'contacts'));
      final raw = box.get('owner_contacts');
      if (raw != null) {
        final decoded = jsonDecode(raw) as List;
        return decoded.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      _logger.e('Failed to read cached emergency contacts', error: e);
    }
    return null;
  }

  Future<void> cacheOwnerQrMetadata(String uid, Map<String, dynamic> qrMetadata) async {
    if (uid.isEmpty) return;
    try {
      // Strip raw secret tokens before saving to offline storage
      final safeMetadata = Map<String, dynamic>.from(qrMetadata);
      safeMetadata.remove('rawToken');
      safeMetadata.remove('rawPayload');

      final box = await Hive.openBox(_getUserBoxName(uid, 'qr_metadata'));
      await box.put('qr_meta', jsonEncode(safeMetadata));
    } catch (e) {
      _logger.e('Failed to cache QR metadata', error: e);
    }
  }

  Future<Map<String, dynamic>?> getCachedOwnerQrMetadata(String uid) async {
    if (uid.isEmpty) return null;
    try {
      final box = await Hive.openBox(_getUserBoxName(uid, 'qr_metadata'));
      final raw = box.get('qr_meta');
      if (raw != null) {
        return jsonDecode(raw) as Map<String, dynamic>;
      }
    } catch (e) {
      _logger.e('Failed to read cached QR metadata', error: e);
    }
    return null;
  }

  /// Clears only the specified user's Hive cache on sign-out to prevent data leaks.
  Future<void> clearUserCache(String uid) async {
    if (uid.isEmpty) return;
    try {
      final boxTypes = ['profile', 'contacts', 'qr_metadata', 'settings'];
      for (final type in boxTypes) {
        final boxName = _getUserBoxName(uid, type);
        if (Hive.isBoxOpen(boxName)) {
          final box = Hive.box(boxName);
          await box.clear();
          await box.close();
        } else {
          await Hive.deleteBoxFromDisk(boxName);
        }
      }
      _logger.i('Successfully cleared local cache for user $uid.');
    } catch (e) {
      _logger.e('Error clearing user cache on logout', error: e);
    }
  }
}
