import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sozotap/caregiver/domain/models/caregiver_relationship_model.dart';
import 'package:sozotap/caregiver/domain/repositories/caregiver_repository.dart';
import 'package:sozotap/caregiver/data/repositories/caregiver_repository_impl.dart';

final caregiverRepositoryProvider = Provider<CaregiverRepository>((ref) {
  return CaregiverRepositoryImpl();
});

final caregiversStreamProvider = StreamProvider<List<CaregiverRelationship>>((ref) {
  final repo = ref.watch(caregiverRepositoryProvider);
  return repo.watchCaregivers();
});
