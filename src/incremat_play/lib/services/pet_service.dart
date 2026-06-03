import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/pet.dart';

class PetService {
  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _pets(String seniorId) =>
      _db.collection('seniors').doc(seniorId).collection('pets');

  CollectionReference<Map<String, dynamic>> _events(String seniorId) =>
      _db.collection('seniors').doc(seniorId).collection('expEvents');

  Stream<List<Pet>> watchPets(String seniorId) => _pets(seniorId)
      .orderBy('awardedAt', descending: false)
      .snapshots()
      .map((snap) =>
          snap.docs.map((d) => Pet.fromMap(d.id, d.data())).toList());

  Future<Pet?> getPet(String seniorId, String petId) async {
    final doc = await _pets(seniorId).doc(petId).get();
    if (!doc.exists) return null;
    return Pet.fromMap(doc.id, doc.data()!);
  }

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
    final now = DateTime.now();
    final pet = Pet(
      id: ref.id,
      seniorId: seniorId,
      stage: PetStage.egg,
      exp: 0,
      awardedAt: now,
      isHatched: false,
    );
    await ref.set(pet.toMap());
    // Record a history milestone for receiving the egg.
    await _events(seniorId).add(ExpEvent(
      id: '',
      date: now,
      petId: ref.id,
      stageBefore: PetStage.egg,
      stageAfter: PetStage.egg,
      amount: 0,
      evolved: false,
      type: HistoryEventType.eggReceived,
    ).toMap());
    return ref.id;
  }

  Future<void> hatchEgg(String seniorId, String petId) async {
    final species =
        PetSpecies.values[DateTime.now().microsecond % PetSpecies.values.length];
    final now = DateTime.now();
    await _pets(seniorId).doc(petId).update({
      'isHatched': true,
      'stage': PetStage.baby.index,
      'species': species.name,
    });
    // Record a history milestone for the hatch.
    await _events(seniorId).add(ExpEvent(
      id: '',
      date: now,
      petId: petId,
      species: species.name,
      stageBefore: PetStage.egg,
      stageAfter: PetStage.baby,
      amount: 0,
      evolved: false,
      type: HistoryEventType.hatched,
    ).toMap());
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
