import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';

/// Handles the senior's lightweight login. Seniors don't have email accounts —
/// they sign in with a JOIN CODE, and under the hood we use Firebase ANONYMOUS
/// auth (so Firestore reads are authenticated) plus a saved senior id in
/// SharedPreferences to remember them. `ensureSignedIn`/`ensureClaimed` make
/// sure a Firebase user exists and the senior is linked before reads happen.
class AuthService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  static const _seniorIdKey = 'senior_id'; // SharedPreferences key for the saved senior
  // Every network call is bounded so the login button can never hang forever.
  static const _timeout = Duration(seconds: 15);

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<String?> signInWithJoinCode(String code, AppLocalizations l) async {
    final upperCode = code.trim().toUpperCase();

    try {
      // Sign in anonymously first so Firestore reads are authenticated.
      if (_auth.currentUser == null) {
        await _auth.signInAnonymously().timeout(_timeout);
      }
      final user = _auth.currentUser;
      if (user == null) {
        return l.couldNotSignIn;
      }
      // Ensure the fresh auth token has propagated to the Firestore SDK before
      // the first authenticated read, otherwise the first attempt can be
      // denied while the token is still settling.
      await user.getIdToken().timeout(_timeout);

      final snap = await _db
          .collection('joinCodes')
          .doc(upperCode)
          .get()
          .timeout(_timeout);
      if (!snap.exists) {
        return l.codeNotFound;
      }

      final seniorId = snap.data()?['seniorId'] as String?;
      if (seniorId == null) {
        return l.codeNotSetUp;
      }

      // Claim this anonymous UID on the senior document so Firestore rules
      // can identify this user on future reads. merge:true so it works whether
      // or not the field already exists (e.g. re-login on a new device).
      await _db
          .collection('seniors')
          .doc(seniorId)
          .set({'seniorUserId': user.uid}, SetOptions(merge: true))
          .timeout(_timeout);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_seniorIdKey, seniorId);

      return null;
    } on TimeoutException {
      return l.connectionTimedOut;
    } on FirebaseException catch (e) {
      switch (e.code) {
        case 'permission-denied':
          return l.codeLinkedOtherDevice;
        case 'operation-not-allowed':
          return l.signInNotEnabled;
        case 'network-request-failed':
          return l.noInternet;
        default:
          return l.errorWithCode(e.code);
      }
    } catch (_) {
      return l.somethingWentWrong;
    }
  }

  Future<String?> getSavedSeniorId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_seniorIdKey);
  }

  /// Signs in by reading a card's UID and looking up the enrolled senior.
  /// Returns null on success, or an error message string on failure.
  Future<String?> signInWithNfcUid(String uid, AppLocalizations l) async {
    try {
      if (_auth.currentUser == null) {
        await _auth.signInAnonymously().timeout(_timeout);
      }
      final user = _auth.currentUser;
      if (user == null) return l.couldNotSignIn;
      await user.getIdToken().timeout(_timeout);

      final doc = await _db.collection('nfc_uids').doc(uid).get().timeout(_timeout);
      if (!doc.exists) {
        return l.cardNotEnrolled;
      }
      final seniorId = doc.data()?['seniorId'] as String?;
      if (seniorId == null) return l.invalidCardData;

      await _db
          .collection('seniors')
          .doc(seniorId)
          .set({'seniorUserId': user.uid}, SetOptions(merge: true))
          .timeout(_timeout);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_seniorIdKey, seniorId);
      return null;
    } on TimeoutException {
      return l.connectionTimedOut;
    } on FirebaseException catch (e) {
      return l.errorWithCode(e.code);
    } catch (_) {
      return l.somethingWentWrong;
    }
  }

  /// Guarantees there is a Firebase user before the app gates into Home.
  /// Anonymous sessions normally persist across launches, but if one was lost
  /// (data cleared, token wipe) this re-establishes one so Firestore reads stay
  /// authenticated. Best-effort; never throws.
  Future<void> ensureSignedIn() async {
    if (_auth.currentUser != null) return;
    try {
      await _auth.signInAnonymously().timeout(_timeout);
      await _auth.currentUser?.getIdToken().timeout(_timeout);
    } catch (_) {
      // Offline / rules — let downstream reads surface the problem.
    }
  }

  /// Re-stamps the current uid onto the senior document. Anonymous uids can
  /// drift (token refresh, partial data clear), leaving seniorUserId pointing
  /// at a stale uid — which makes Firestore rules deny access to the pets /
  /// expEvents sub-collections. Calling this on every launch keeps them in
  /// sync so the saved account stays accessible. Best-effort; never throws.
  Future<void> ensureClaimed(String seniorId) async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      await _db
          .collection('seniors')
          .doc(seniorId)
          .set({'seniorUserId': user.uid}, SetOptions(merge: true))
          .timeout(_timeout);
    } catch (_) {
      // Ignore — rules/network issues shouldn't block the app from loading.
    }
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_seniorIdKey);
    await _auth.signOut();
  }
}
