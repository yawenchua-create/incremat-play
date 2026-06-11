import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/duet_session.dart';
import '../models/live_session.dart';
import '../models/pet.dart';
import '../models/senior.dart';

class SeniorService {
  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _duets =>
      _db.collection('duets');

  // Avoids easily-confused characters (no O/0, I/1).
  static const _codeAlphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  String _genDuetCode() {
    final r = Random.secure();
    return List.generate(
        6, (_) => _codeAlphabet[r.nextInt(_codeAlphabet.length)]).join();
  }

  /// Creates a new lobby hosted by this senior and returns its share code.
  /// [mode] selects cooperative (combined meter) or versus (head-to-head race).
  Future<String> createDuet({
    required String seniorId,
    required String name,
    required int goal,
    DuetMode mode = DuetMode.coop,
  }) async {
    var code = _genDuetCode();
    // A couple of collision retries — the space is ~10^9 so this is ample.
    for (var i = 0; i < 4; i++) {
      if (!(await _duets.doc(code).get()).exists) break;
      code = _genDuetCode();
    }
    await _duets.doc(code).set({
      'mode': mode.name,
      'hostId': seniorId,
      'hostName': name,
      'hostGoal': goal,
      'guestId': null,
      'guestName': null,
      'guestGoal': null,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    });
    return code;
  }

  /// Joins an existing duet as the guest. Returns null on success, or an error
  /// message. Idempotent if you're already a participant.
  Future<String?> joinDuet({
    required String code,
    required String seniorId,
    required String name,
    required int goal,
  }) async {
    final upper = code.trim().toUpperCase();
    if (upper.isEmpty) return 'Enter a duet code.';
    final ref = _duets.doc(upper);
    final snap = await ref.get();
    if (!snap.exists) return 'That duet code wasn\'t found.';
    final data = snap.data()!;
    if (data['hostId'] == seniorId) return null; // already the host
    final guestId = data['guestId'] as String?;
    if (guestId != null && guestId != seniorId) {
      return 'That duet is already full.';
    }
    await ref.set({
      'guestId': seniorId,
      'guestName': name,
      'guestGoal': goal,
    }, SetOptions(merge: true));
    return null;
  }

  Stream<DuetSession?> watchDuet(String code) => _duets
      .doc(code.trim().toUpperCase())
      .snapshots()
      .map((s) => s.exists ? DuetSession.fromMap(s.id, s.data()!) : null);

  /// Tears down a duet. The host deletes the lobby; a guest just steps out.
  Future<void> leaveDuet(String code, {required bool asHost}) async {
    final ref = _duets.doc(code.trim().toUpperCase());
    try {
      if (asHost) {
        await ref.delete();
      } else {
        await ref.set({
          'guestId': null,
          'guestName': null,
          'guestGoal': null,
        }, SetOptions(merge: true));
      }
    } catch (_) {}
  }

  /// Mirrors the live rep count this device is reading straight from the mat
  /// up to Firestore, so a remote caregiver and competitive/duet partner can
  /// still see it. Best-effort; the doc auto-expires from `isLive` after 5 min
  /// of silence so we never need an explicit clear that could race the
  /// caregiver app's own writes.
  Future<void> publishLive(String seniorId, int reps) async {
    try {
      await _db
          .collection('seniors')
          .doc(seniorId)
          .collection('live')
          .doc('current')
          .set({
        'active': true,
        'repCount': reps,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      }, SetOptions(merge: true));
    } catch (_) {
      // Offline / rules — local BLE view keeps working regardless.
    }
  }

  /// Live (in-progress) session published by the caregiver app while the
  /// senior is exercising on the mat.
  Stream<LiveSession?> watchLiveSession(String seniorId) => _db
      .collection('seniors')
      .doc(seniorId)
      .collection('live')
      .doc('current')
      .snapshots()
      .map((snap) =>
          snap.exists ? LiveSession.fromMap(snap.data()!) : null);

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

  Stream<List<ExpEvent>> watchExpEvents(String seniorId) => _db
      .collection('seniors')
      .doc(seniorId)
      .collection('expEvents')
      .snapshots()
      .map((snap) {
        final events = snap.docs
            .map((d) => ExpEvent.fromMap(d.id, d.data()))
            .toList();
        events.sort((a, b) => b.date.compareTo(a.date));
        return events;
      });

  /// Returns the timestamp that game logic was last run up to, or null if
  /// the senior has never had any sessions processed.
  Future<DateTime?> getLastGameProcessedAt(String seniorId) async {
    final doc = await _db.collection('seniors').doc(seniorId).get();
    final raw = doc.data()?['lastGameProcessedAt'] as String?;
    return raw != null ? DateTime.tryParse(raw) : null;
  }

  /// Fetches all sessions with a timestamp strictly after [since].
  /// Pass null to fetch every session (first-run catch-up).
  Future<List<ExerciseSession>> getSessionsSince(
      String seniorId, DateTime? since) async {
    Query<Map<String, dynamic>> q = _db
        .collection('seniors')
        .doc(seniorId)
        .collection('sessions');
    if (since != null) {
      q = q.where('timestamp',
          isGreaterThan: since.millisecondsSinceEpoch);
    }
    final snap = await q.get();
    return snap.docs
        .map((d) => ExerciseSession.fromMap(d.id, d.data()))
        .toList();
  }

  /// Persists the high-water mark so the next launch knows where to resume.
  Future<void> markGameProcessed(String seniorId, DateTime upTo) async {
    await _db.collection('seniors').doc(seniorId).set(
      {'lastGameProcessedAt': upTo.toIso8601String()},
      SetOptions(merge: true),
    );
  }

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
