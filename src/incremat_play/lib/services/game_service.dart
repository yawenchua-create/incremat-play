import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/senior.dart';
import '../models/pet.dart';
import 'consistency_service.dart';
import 'pet_service.dart';
import 'senior_service.dart';

class GameService {
  final _petService = PetService();
  final _seniorService = SeniorService();
  final _db = FirebaseFirestore.instance;

  /// Called when a new exercise session is logged for a senior.
  /// Checks if an egg should be awarded, and awards EXP to the active pet.
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

    final activePet = await _petService.getActivePet(seniorId);
    bool evolved = false;
    if (activePet != null && activePet.stage != PetStage.adult) {
      final stageBefore = activePet.stage;
      await _petService.addExp(seniorId, activePet.id, 1);
      final updated = await _petService.getActivePet(seniorId);
      evolved = updated != null && updated.stage != stageBefore;
    }

    return EggAwardResult(eggAwarded: eggAwarded, evolved: evolved);
  }

  Future<String?> _getLastEggAwardedWeek(String seniorId) async {
    final snap =
        await _db.collection('seniors').doc(seniorId).get();
    return snap.data()?['lastEggAwardedWeek'] as String?;
  }

  Future<void> _setLastEggAwardedWeek(String seniorId, String week) async {
    await _db
        .collection('seniors')
        .doc(seniorId)
        .update({'lastEggAwardedWeek': week});
  }
}

class EggAwardResult {
  final bool eggAwarded;
  final bool evolved;

  const EggAwardResult({required this.eggAwarded, required this.evolved});
}
