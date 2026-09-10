import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/repositories/settings_repository.dart';
import '../../domain/models/privacy_settings_model.dart';
import '../../../core/offline/hive_cache_service.dart';
import '../../../core/offline/connectivity_service.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Initialize sharedPreferencesProvider in main.dart');
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SettingsRepository(prefs: prefs);
});

final privacySettingsStreamProvider = StreamProvider<PrivacySettingsModel>((ref) {
  final repository = ref.watch(settingsRepositoryProvider);
  return repository.getPrivacySettingsStream();
});

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  final repository = ref.watch(settingsRepositoryProvider);
  return ThemeModeNotifier(repository);
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final SettingsRepository _repository;

  ThemeModeNotifier(this._repository) : super(ThemeMode.system) {
    _init();
  }

  void _init() {
    final rawMode = _repository.getThemeMode();
    state = _parseThemeMode(rawMode);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final modeStr = mode.name; // system, light, dark
    await _repository.setThemeMode(modeStr);
  }

  ThemeMode _parseThemeMode(String raw) {
    switch (raw) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}

final hiveCacheServiceProvider = Provider<HiveCacheService>((ref) {
  return HiveCacheService();
});

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  final service = ConnectivityService();
  ref.onDispose(() => service.dispose());
  return service;
});

final isOfflineProvider = StreamProvider<bool>((ref) {
  final connectivityService = ref.watch(connectivityServiceProvider);
  return connectivityService.onConnectivityChanged.map((isOnline) => !isOnline);
});
