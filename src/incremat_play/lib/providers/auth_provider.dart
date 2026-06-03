import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authStateProvider = StreamProvider<User?>(
  (ref) => ref.watch(authServiceProvider).authStateChanges,
);

final seniorIdProvider = FutureProvider<String?>((ref) async {
  // Watch the auth VALUE (not .future) so this re-runs on every auth emission —
  // including the anonymous user that appears right after the first sign-in.
  // Using .future only resolved once (to the startup null), which left the app
  // stuck on the login screen until a second sign-in attempt.
  final authState = ref.watch(authStateProvider);
  if (authState.isLoading) return null;
  final user = authState.valueOrNull;
  if (user == null) return null;
  final authService = ref.read(authServiceProvider);
  final id = await authService.getSavedSeniorId();
  if (id != null) {
    // Heal any uid drift so Firestore rules keep granting access to the
    // pets / expEvents sub-collections for this account.
    await authService.ensureClaimed(id);
  }
  return id;
});
