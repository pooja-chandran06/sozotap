import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/admin_notification_settings.dart';
import '../../data/repositories/admin_notification_settings_repository.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';

final adminNotificationSettingsRepoProvider = Provider<AdminNotificationSettingsRepository>((ref) {
  return AdminNotificationSettingsRepository();
});

class AdminNotificationSettingsState {
  final AdminNotificationSettings? settings;
  final bool isLoading;
  final String? error;

  const AdminNotificationSettingsState({
    this.settings,
    this.isLoading = false,
    this.error,
  });

  AdminNotificationSettingsState copyWith({
    AdminNotificationSettings? settings,
    bool? isLoading,
    String? error,
  }) {
    return AdminNotificationSettingsState(
      settings: settings ?? this.settings,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AdminNotificationSettingsNotifier extends StateNotifier<AdminNotificationSettingsState> {
  final AdminNotificationSettingsRepository _repository;
  final String userId;

  AdminNotificationSettingsNotifier(this._repository, this.userId)
      : super(const AdminNotificationSettingsState()) {
    loadSettings();
  }

  Future<void> loadSettings() async {
    if (userId.isEmpty) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final s = await _repository.getSettings(userId);
      state = state.copyWith(settings: s, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> saveSettings(AdminNotificationSettings newSettings) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.saveSettings(newSettings);
      state = state.copyWith(settings: newSettings, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }
}

final adminNotificationSettingsProvider =
    StateNotifierProvider<AdminNotificationSettingsNotifier, AdminNotificationSettingsState>((ref) {
  final user = ref.watch(authStateProvider).value;
  return AdminNotificationSettingsNotifier(
    ref.watch(adminNotificationSettingsRepoProvider),
    user?.id ?? '',
  );
});
