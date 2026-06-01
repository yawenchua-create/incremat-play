import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/senior.dart';
import '../models/pet.dart';

class SeniorService {
  final _db = FirebaseFirestore.instance;

  Stream<Senior?> watchSenior(String seniorId) => _db
      .collection('seniors')
      .doc(seniorId)
      .snapshots()
      .map((snap) =>
          snap.exists ? Senior.fromMap(snap.id, snap.data()!) : null);

  Stream<List<ExerciseSession>> watchRecentSessions(String seniorId) => _db
      .collection('seniors')
      .doc(seniorId)
      .collection('sessions')
      .orderBy('timestamp', descending: true)
      .limit(30)
      .snapshots()
      .map((snap) => snap.docs
          .map((d) => ExerciseSession.fromMap(d.id, d.data()))
          .toList());

  Future<List<ExerciseSession>> getSessionsForWeek(
      String seniorId, DateTime weekStart) async {
    final weekEnd = weekStart.add(const Duration(days: 7));
    final snap = await _db
        .collection('seniors')
        .doc(seniorId)
        .collection('sessions')
        .where('timestamp',
            isGreaterThanOrEqualTo: weekStart.millisecondsSinceEpoch,
            isLessThan: weekEnd.millisecondsSinceEpoch)
        .get();
    return snap.docs
        .map((d) => ExerciseSession.fromMap(d.id, d.data()))
        .toList();
  }
}
