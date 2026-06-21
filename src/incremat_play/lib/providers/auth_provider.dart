import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';

// ════════════════════════════════════════════════════════════════════════════
// Auth for the Play app. Seniors sign in with a JOIN CODE (not email/password) —
// the app signs into Firebase ANONYMOUSLY behind the scenes so Firestore reads
// are authenticated, and remembers the senior id locally so they stay logged in.
// ════════════════════════════════════════════════════════════════════════════

// Shared AuthService instance for the providers below.
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

// The raw Firebase auth stream (the anonymous user). Most of the app gates on
// seniorIdProvider below instead — see the note there for why.
final authStateProvider = StreamProvider<User?>(
  (ref) => ref.watch(authServiceProvider).authStateChanges,
);

// The single source of truth for "is the user logged in". Reads the saved
// senior ID from SharedPreferences — NOT from authStateChanges. The auth stream
// emits a microtask *after* signInAnonymously() resolves, so gating on it forced
// a second login attempt. By gating only on this provider (invalidated right
// after login/sign-out) the transition is deterministic and happens on the
// first try. When a senior is saved we also guarantee a Firebase user exists so
// Firestore reads stay authenticated.
final seniorIdProvider = FutureProvider<String?>((ref) async {
  final authService = ref.read(authServiceProvider);
  final id = await authService.getSavedSeniorId();
  if (id == null) return null;
  await authService.ensureSignedIn();
  await authService.ensureClaimed(id);
  return id;
});
