import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  static const _seniorIdKey = 'senior_id';
  // Every network call is bounded so the login button can never hang forever.
  static const _timeout = Duration(seconds: 15);

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<String?> signInWithJoinCode(String code) async {
    final upperCode = code.trim().toUpperCase();

    try {
      // Sign in anonymously first so Firestore reads are authenticated.
      if (_auth.currentUser == null) {
        await _auth.signInAnonymously().timeout(_timeout);
      }
      final user = _auth.currentUser;
      if (user == null) {
        return 'Could not sign in. Please try again.';
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
        return 'Code not found. Check the code and try again.';
      }

      final seniorId = snap.data()?['seniorId'] as String?;
      if (seniorId == null) {
        return 'This code is not set up correctly. Ask your caregiver.';
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
      return 'Connection timed out. Check your internet and try again.';
    } on FirebaseException catch (e) {
      switch (e.code) {
        case 'permission-denied':
          return 'This code is linked to another device. Ask your caregiver.';
        case 'operation-not-allowed':
          return 'Sign-in is not enabled for this app. Ask your caregiver.';
        case 'network-request-failed':
          return 'No internet connection. Please try again.';
        default:
          return 'Something went wrong (${e.code}). Please try again.';
      }
    } catch (_) {
      return 'Something went wrong. Please try again.';
    }
  }

  Future<String?> getSavedSeniorId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_seniorIdKey);
  }

  /// Signs in by reading a card's UID and looking up the enrolled senior.
  /// Returns null on success, or an error message string on failure.
  Future<String?> signInWithNfcUid(String uid) async {
    try {
      if (_auth.currentUser == null) {
        await _auth.signInAnonymously().timeout(_timeout);
      }
      final user = _auth.currentUser;
      if (user == null) return 'Could not sign in. Please try again.';
      await user.getIdToken().timeout(_timeout);

      final doc = await _db.collection('nfc_uids').doc(uid).get().timeout(_timeout);
      if (!doc.exists) {
        return 'This card has not been enrolled. Ask your caregiver to set it up.';
      }
      final seniorId = doc.data()?['seniorId'] as String?;
      if (seniorId == null) return 'Invalid card data. Ask your caregiver.';

      await _db
          .collection('seniors')
          .doc(seniorId)
          .set({'seniorUserId': user.uid}, SetOptions(merge: true))
          .timeout(_timeout);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_seniorIdKey, seniorId);
      return null;
    } on TimeoutException {
      return 'Connection timed out. Check your internet and try again.';
    } on FirebaseException catch (e) {
      return 'Something went wrong (${e.code}). Please try again.';
    } catch (_) {
      return 'Something went wrong. Please try again.';
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
