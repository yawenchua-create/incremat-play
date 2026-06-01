import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/senior.dart';
import '../models/pet.dart';
import '../services/senior_service.dart';
import '../services/pet_service.dart';
import 'auth_provider.dart';

final seniorServiceProvider = Provider<SeniorService>((ref) => SeniorService());
final petServiceProvider = Provider<PetService>((ref) => PetService());

final seniorProvider = StreamProvider<Senior?>((ref) {
  final idAsync = ref.watch(seniorIdProvider);
  return idAsync.when(
    data: (id) {
      if (id == null) return const Stream.empty();
      return ref.watch(seniorServiceProvider).watchSenior(id);
    },
    loading: () => const Stream.empty(),
    error: (_, _) => const Stream.empty(),
  );
});

final petsProvider = StreamProvider<List<Pet>>((ref) {
  final idAsync = ref.watch(seniorIdProvider);
  return idAsync.when(
    data: (id) {
      if (id == null) return const Stream.empty();
      return ref.watch(petServiceProvider).watchPets(id);
    },
    loading: () => const Stream.empty(),
    error: (_, _) => const Stream.empty(),
  );
});

// Derives the active pet (most recently awarded hatched pet) from the live
// petsProvider stream so it updates immediately after hatch or EXP changes.
final activePetProvider = Provider<Pet?>((ref) {
  final pets = ref.watch(petsProvider).valueOrNull ?? [];
  final hatched = pets.where((p) => p.isHatched).toList()
    ..sort((a, b) => b.awardedAt.compareTo(a.awardedAt));
  return hatched.isEmpty ? null : hatched.first;
});

final sessionsProvider = StreamProvider<List<ExerciseSession>>((ref) {
  final idAsync = ref.watch(seniorIdProvider);
  return idAsync.when(
    data: (id) {
      if (id == null) return const Stream.empty();
      return ref.watch(seniorServiceProvider).watchRecentSessions(id);
    },
    loading: () => const Stream.empty(),
    error: (_, _) => const Stream.empty(),
  );
});
