import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/senior.dart';
import '../models/pet.dart';
import 'consistency_service.dart';
import 'pet_service.dart';
import 'senior_service.dart';

/// The gamification BRAIN. After a session is logged it decides what the senior
/// earns: whether they hit the weekly consistency bar to be awarded an egg, and
/// how EXP/evolution applies to their pet. It orchestrates the three lower-level
/// services — ConsistencyService (the rules), PetService (pet data), and
/// SeniorService (session data) — rather than touching Firestore for everything
/// itself. This separation keeps the "what counts as progress" rules in one place.
class GameService {
  final _petService = PetService();
  final _seniorService = SeniorService();
  final _db = FirebaseFirestore.instance;

  Future<EggAwardResult> onSessionLogged({
    required String seniorId,
    required Senior senior,
    required DateTime sessionDate,
  }) async {
    final weekStart = ConsistencyService.weekStart(sessionDate);
    final sessionsThisWeek =
        await _seniorService.getSessionsForWeek(seniorId, weekStart);

    final lastEggWeek = await _getLastEggAwardedWeek(seniorId);

    bool eggAwarded = false;
    if (ConsistencyService.shouldAwardEgg(
      completionDate: sessionDate,
      sessionsThisWeek: sessionsThisWeek,
      senior: senior,
      lastEggAwardedWeek: lastEggWeek,
    )) {
      await _petService.awardEgg(seniorId);
      await _setLastEggAwardedWeek(
          seniorId, ConsistencyService.isoWeek(sessionDate));
      eggAwarded = true;
    }

    // EXP is awarded at most ONCE per day, and only on a day the senior
    // actually completes their daily rep goal. Without these guards every
    // logged session granted +1 EXP, so the pet gained EXP continuously.
    bool evolved = false;
    final dayKey = ConsistencyService.dayKey(sessionDate);
    final goalMet = ConsistencyService.goalMetOn(
        sessionsThisWeek, sessionDate, senior.dailyRepGoal);
    final lastExpDay = await _getLastExpAwardedDay(seniorId);

    if (goalMet && lastExpDay != dayKey) {
      final activePet = await _petService.getActivePet(seniorId);
      // Only consume the day's award when a pet actually exists, so a pet
      // hatched later the same day can still receive its first EXP.
      if (activePet != null) {
        if (activePet.stage != PetStage.adult) {
          final stageBefore = activePet.stage;
          await _petService.addExp(seniorId, activePet.id, 1);
          final updated = await _petService.getActivePet(seniorId);
          evolved = updated != null && updated.stage != stageBefore;

          await _db
              .collection('seniors')
              .doc(seniorId)
              .collection('expEvents')
              .add(ExpEvent(
                id: '',
                date: sessionDate,
                petId: activePet.id,
                species: activePet.species?.name,
                stageBefore: stageBefore,
                stageAfter: updated?.stage ?? stageBefore,
                amount: 1,
                evolved: evolved,
              ).toMap());
        }
        await _setLastExpAwardedDay(seniorId, dayKey);
      }
    }

    return EggAwardResult(eggAwarded: eggAwarded, evolved: evolved);
  }

  Future<String?> _getLastEggAwardedWeek(String seniorId) async {
    final snap = await _db.collection('seniors').doc(seniorId).get();
    return snap.data()?['lastEggAwardedWeek'] as String?;
  }

  Future<void> _setLastEggAwardedWeek(String seniorId, String week) async {
    await _db
        .collection('seniors')
        .doc(seniorId)
        .update({'lastEggAwardedWeek': week});
  }

  Future<String?> _getLastExpAwardedDay(String seniorId) async {
    final snap = await _db.collection('seniors').doc(seniorId).get();
    return snap.data()?['lastExpAwardedDay'] as String?;
  }

  Future<void> _setLastExpAwardedDay(String seniorId, String day) async {
    await _db
        .collection('seniors')
        .doc(seniorId)
        .update({'lastExpAwardedDay': day});
  }
}

class EggAwardResult {
  final bool eggAwarded;
  final bool evolved;

  const EggAwardResult({required this.eggAwarded, required this.evolved});
}
