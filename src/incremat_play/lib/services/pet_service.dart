import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/pet.dart';

class PetService {
  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _pets(String seniorId) =>
      _db.collection('seniors').doc(seniorId).collection('pets');

  Stream<List<Pet>> watchPets(String seniorId) => _pets(seniorId)
      .orderBy('awardedAt', descending: false)
      .snapshots()
      .map((snap) =>
          snap.docs.map((d) => Pet.fromMap(d.id, d.data())).toList());

  Future<Pet?> getActivePet(String seniorId) async {
    final snap = await _pets(seniorId)
        .where('isHatched', isEqualTo: true)
        .orderBy('awardedAt', descending: true)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return Pet.fromMap(snap.docs.first.id, snap.docs.first.data());
  }

  Future<List<Pet>> getUnhatchedEggs(String seniorId) async {
    final snap = await _pets(seniorId)
        .where('isHatched', isEqualTo: false)
        .where('stage', isEqualTo: PetStage.egg.index)
        .orderBy('awardedAt', descending: false)
        .get();
    return snap.docs.map((d) => Pet.fromMap(d.id, d.data())).toList();
  }

  Future<String> awardEgg(String seniorId) async {
    final ref = _pets(seniorId).doc();
    final pet = Pet(
      id: ref.id,
      seniorId: seniorId,
      stage: PetStage.egg,
      exp: 0,
      awardedAt: DateTime.now(),
      isHatched: false,
    );
    await ref.set(pet.toMap());
    return ref.id;
  }

  Future<void> hatchEgg(String seniorId, String petId) async {
    final species =
        PetSpecies.values[DateTime.now().microsecond % PetSpecies.values.length];
    await _pets(seniorId).doc(petId).update({
      'isHatched': true,
      'stage': PetStage.baby.index,
      'speciesIndex': species.index,
    });
  }

  Future<void> addExp(String seniorId, String petId, int amount) async {
    final doc = await _pets(seniorId).doc(petId).get();
    if (!doc.exists) return;
    final pet = Pet.fromMap(doc.id, doc.data()!);
    if (pet.stage == PetStage.adult) return;

    var newExp = pet.exp + amount;
    var newStage = pet.stage;

    while (newStage != PetStage.adult) {
      final needed = newStage.expToNext;
      if (needed <= 0) break; // guard against adult stage with expToNext == 0
      if (newExp >= needed) {
        newExp -= needed;
        newStage = PetStage.values[newStage.index + 1];
      } else {
        break;
      }
    }

    await _pets(seniorId).doc(petId).update({
      'exp': newExp,
      'stage': newStage.index,
    });
  }
}
