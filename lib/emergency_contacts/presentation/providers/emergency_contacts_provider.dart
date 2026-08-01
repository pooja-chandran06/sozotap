import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../data/datasources/emergency_contact_remote_datasource.dart';
import '../../data/repositories/emergency_contact_repository_impl.dart';
import '../../domain/models/emergency_contact.dart';
import '../../domain/repositories/emergency_contact_repository.dart';
import '../../domain/use_cases/get_emergency_contacts.dart';
import '../../domain/use_cases/save_emergency_contact.dart';
import '../../domain/use_cases/delete_emergency_contact.dart';
import '../../../core/security/phone_normalizer.dart';

final emergencyContactRemoteDataSourceProvider = Provider<EmergencyContactRemoteDataSource>((ref) {
  return EmergencyContactRemoteDataSource();
});

final emergencyContactRepositoryProvider = Provider<EmergencyContactRepository>((ref) {
  return EmergencyContactRepositoryImpl(ref.watch(emergencyContactRemoteDataSourceProvider));
});

final phoneNormalizerProvider = Provider<PhoneNormalizer>((ref) => PhoneNormalizer());

final getEmergencyContactsProvider = Provider<GetEmergencyContacts>((ref) {
  return GetEmergencyContacts(ref.watch(emergencyContactRepositoryProvider));
});

final saveEmergencyContactProvider = Provider<SaveEmergencyContact>((ref) {
  return SaveEmergencyContact(
    ref.watch(emergencyContactRepositoryProvider),
    ref.watch(phoneNormalizerProvider),
  );
});

final deleteEmergencyContactProvider = Provider<DeleteEmergencyContact>((ref) {
  return DeleteEmergencyContact(ref.watch(emergencyContactRepositoryProvider));
});

class EmergencyContactsState {
  final List<EmergencyContact> contacts;
  final bool isLoading;
  final String? error;

  const EmergencyContactsState({
    this.contacts = const [],
    this.isLoading = false,
    this.error,
  });

  EmergencyContactsState copyWith({
    List<EmergencyContact>? contacts,
    bool? isLoading,
    String? error,
  }) {
    return EmergencyContactsState(
      contacts: contacts ?? this.contacts,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class EmergencyContactsNotifier extends StateNotifier<EmergencyContactsState> {
  final GetEmergencyContacts _getContacts;
  final SaveEmergencyContact _saveContact;
  final DeleteEmergencyContact _deleteContact;
  final String _userId;

  EmergencyContactsNotifier(
    this._getContacts,
    this._saveContact,
    this._deleteContact,
    this._userId,
  ) : super(const EmergencyContactsState()) {
    loadContacts();
  }

  Future<void> loadContacts() async {
    if (_userId.isEmpty) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final contacts = await _getContacts.execute(_userId);
      state = state.copyWith(contacts: contacts, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> save(EmergencyContact contact) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _saveContact.execute(contact);
      await loadContacts();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> delete(String contactId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _deleteContact.execute(_userId, contactId);
      await loadContacts();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final emergencyContactsProvider = StateNotifierProvider<EmergencyContactsNotifier, EmergencyContactsState>((ref) {
  final user = ref.watch(authStateProvider).value;
  return EmergencyContactsNotifier(
    ref.watch(getEmergencyContactsProvider),
    ref.watch(saveEmergencyContactProvider),
    ref.watch(deleteEmergencyContactProvider),
    user?.id ?? '',
  );
});
