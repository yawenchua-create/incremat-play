import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/senior.dart';
import '../models/pet.dart';
import '../models/live_session.dart';
import '../models/duet_session.dart';
import '../services/senior_service.dart';
import '../services/pet_service.dart';
import 'auth_provider.dart';

// ════════════════════════════════════════════════════════════════════════════
// The Play app's central STATE HUB (mirrors the caregiver app's senior_provider).
// It exposes the logged-in senior, their pet, the live session, and duet state
// as providers the screens watch. `seniorIdProvider` (in auth_provider) is the
// root: most providers below `ref.watch` it and rebuild when the senior changes.
// ════════════════════════════════════════════════════════════════════════════

// Shared service instances for the providers below.
final seniorServiceProvider = Provider<SeniorService>((ref) => SeniorService());
final petServiceProvider = Provider<PetService>((ref) => PetService());

/// The live Senior document for whoever is signed in (null when none). Chains
/// off seniorIdProvider: when the id is known, watch that senior's Firestore doc.
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

// User-selected active pet ID; null = default (most recently awarded).
final selectedPetIdProvider = StateProvider<String?>((ref) => null);

// All hatched pets sorted newest-first.
final hatchedPetsProvider = Provider<List<Pet>>((ref) {
  final pets = ref.watch(petsProvider).valueOrNull ?? [];
  return pets.where((p) => p.isHatched).toList()
    ..sort((a, b) => b.awardedAt.compareTo(a.awardedAt));
});

final activePetProvider = Provider<Pet?>((ref) {
  final hatched = ref.watch(hatchedPetsProvider);
  if (hatched.isEmpty) return null;
  final selectedId = ref.watch(selectedPetIdProvider);
  if (selectedId != null) {
    final match = hatched.where((p) => p.id == selectedId).firstOrNull;
    if (match != null) return match;
  }
  return hatched.first;
});

/// Disambiguates pets of the same species: returns the 1-based ordinal of
/// [pet] among all hatched pets of its species (oldest first) and how many
/// there are. Lets the UI show "#2" when you own two of the same companion.
({int index, int count}) speciesOrdinal(Pet pet, List<Pet> hatched) {
  if (pet.species == null) return (index: 1, count: 1);
  final same = hatched.where((p) => p.species == pet.species).toList()
    ..sort((a, b) => a.awardedAt.compareTo(b.awardedAt));
  final idx = same.indexWhere((p) => p.id == pet.id);
  return (index: idx < 0 ? 1 : idx + 1, count: same.length);
}

/// Highest stage index ever reached per species across all hatched pets.
/// Used to keep evolutions you haven't unlocked yet a secret.
Map<PetSpecies, int> maxStageReachedBySpecies(List<Pet> hatched) {
  final map = <PetSpecies, int>{};
  for (final p in hatched) {
    final sp = p.species;
    if (sp == null) continue;
    final cur = map[sp] ?? -1;
    if (p.stage.index > cur) map[sp] = p.stage.index;
  }
  return map;
}

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

final liveSessionProvider = StreamProvider<LiveSession?>((ref) {
  // Use valueOrNull so the subscription starts the moment the ID is available,
  // without waiting for a full .when() cycle (loading → data transition).
  final id = ref.watch(seniorIdProvider).valueOrNull;
  if (id == null) return const Stream.empty();
  return ref.read(seniorServiceProvider).watchLiveSession(id);
});

// Live session of any senior by id — used to watch a Duet partner's reps.
final partnerLiveProvider =
    StreamProvider.family<LiveSession?, String>((ref, seniorId) {
  return ref.watch(seniorServiceProvider).watchLiveSession(seniorId);
});

// The duet lobby code this device is currently in (persisted across runs).
class DuetCodeNotifier extends Notifier<String?> {
  static const _key = 'duet_code';

  @override
  String? build() {
    _load();
    return null;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_key);
    if (code != null) state = code;
  }

  Future<void> setCode(String? code) async {
    state = code;
    final prefs = await SharedPreferences.getInstance();
    if (code == null) {
      await prefs.remove(_key);
    } else {
      await prefs.setString(_key, code);
    }
  }
}

final duetCodeProvider =
    NotifierProvider<DuetCodeNotifier, String?>(DuetCodeNotifier.new);

// Live view of a duet lobby by its code.
final duetSessionProvider =
    StreamProvider.family<DuetSession?, String>((ref, code) {
  return ref.watch(seniorServiceProvider).watchDuet(code);
});

final expEventsProvider = StreamProvider<List<ExpEvent>>((ref) {
  final idAsync = ref.watch(seniorIdProvider);
  return idAsync.when(
    data: (id) {
      if (id == null) return const Stream.empty();
      return ref.watch(seniorServiceProvider).watchExpEvents(id);
    },
    loading: () => const Stream.empty(),
    error: (_, _) => const Stream.empty(),
  );
});
