import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/templates_admin_repository.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';

final templatesAdminRepositoryProvider = Provider<TemplatesAdminRepository>((ref) {
  return TemplatesAdminRepository();
});

final templatesAdminNotifierUserIdProvider = Provider<String>((ref) {
  final user = ref.watch(authStateProvider).value;
  return user?.id ?? '';
});

final userAdminRoleProvider = FutureProvider<String>((ref) async {
  final authUser = ref.watch(authStateProvider).value;
  if (authUser == null) return '';
  final repo = ref.watch(templatesAdminRepositoryProvider);
  return repo.getAdminRole(authUser.id);
});

final isAdminProvider = FutureProvider<bool>((ref) async {
  final role = await ref.watch(userAdminRoleProvider.future);
  return role.isNotEmpty;
});

class TemplatesAdminState {
  final List<TemplateMetadata> templates;
  final bool isLoading;
  final String? error;
  final String userRole;
  final String? selectedFilterType;
  final String? selectedFilterLocale;

  const TemplatesAdminState({
    this.templates = const [],
    this.isLoading = false,
    this.error,
    this.userRole = '',
    this.selectedFilterType,
    this.selectedFilterLocale,
  });

  TemplatesAdminState copyWith({
    List<TemplateMetadata>? templates,
    bool? isLoading,
    String? error,
    String? userRole,
    String? selectedFilterType,
    String? selectedFilterLocale,
  }) {
    return TemplatesAdminState(
      templates: templates ?? this.templates,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      userRole: userRole ?? this.userRole,
      selectedFilterType: selectedFilterType ?? this.selectedFilterType,
      selectedFilterLocale: selectedFilterLocale ?? this.selectedFilterLocale,
    );
  }
}

class TemplatesAdminNotifier extends StateNotifier<TemplatesAdminState> {
  final TemplatesAdminRepository _repository;
  final String userId;

  TemplatesAdminNotifier(this._repository, this.userId) : super(const TemplatesAdminState()) {
    init();
  }

  Future<void> init() async {
    if (userId.isEmpty) return;
    state = state.copyWith(isLoading: true);
    try {
      final role = await _repository.getAdminRole(userId);
      final list = await _repository.listTemplates(userRole: role);
      state = state.copyWith(userRole: role, templates: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> toggleEnabled(String docId, bool currentStatus) async {
    try {
      await _repository.toggleEnabled(docId, !currentStatus, userId, state.userRole);
      await init();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> saveTemplate(TemplateDocument doc, {bool isRestoration = false, String? restoredFromAuditLogId}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.saveTemplate(
        doc,
        userId,
        state.userRole,
        isRestoration: isRestoration,
        restoredFromAuditLogId: restoredFromAuditLogId,
      );
      await init();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  void filterByType(String? type) {
    state = state.copyWith(selectedFilterType: type);
  }

  void filterByLocale(String? locale) {
    state = state.copyWith(selectedFilterLocale: locale);
  }
}

final templatesAdminProvider = StateNotifierProvider<TemplatesAdminNotifier, TemplatesAdminState>((ref) {
  final user = ref.watch(authStateProvider).value;
  return TemplatesAdminNotifier(
    ref.watch(templatesAdminRepositoryProvider),
    user?.id ?? '',
  );
});
