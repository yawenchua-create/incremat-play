import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  static const _seniorIdKey = 'senior_id';

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<String?> signInWithJoinCode(String code) async {
    final upperCode = code.trim().toUpperCase();

    try {
      // Sign in anonymously first so Firestore reads are authenticated.
      if (_auth.currentUser == null) {
        await _auth.signInAnonymously();
      }
      final user = _auth.currentUser!;

      final snap = await _db.collection('joinCodes').doc(upperCode).get();
      if (!snap.exists) {
        await signOut();
        return 'Code not found. Check the code and try again.';
      }

      final seniorId = snap.data()?['seniorId'] as String?;
      if (seniorId == null) {
        await signOut();
        return 'Invalid code.';
      }

      // Claim this anonymous UID on the senior document so Firestore rules
      // can identify this user on future reads. Also verifies the senior
      // document exists (update() throws if the document is missing).
      await _db.collection('seniors').doc(seniorId).update({'seniorUserId': user.uid});

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_seniorIdKey, seniorId);

      return null;
    } catch (e) {
      try { await signOut(); } catch (_) {}
      return 'Something went wrong. Please try again.';
    }
  }

  Future<String?> getSavedSeniorId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_seniorIdKey);
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_seniorIdKey);
    await _auth.signOut();
  }
}
