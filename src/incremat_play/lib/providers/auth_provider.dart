import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authStateProvider = StreamProvider<User?>(
  (ref) => ref.watch(authServiceProvider).authStateChanges,
);

// Reads the saved senior ID from SharedPreferences only.
// Does NOT watch authStateProvider — that caused a race where signInAnonymously()
// fired authStateChanges before SharedPreferences was written, returning null
// mid-login and forcing a second attempt.
// This provider is invalidated explicitly after login and sign-out.
final seniorIdProvider = FutureProvider<String?>((ref) async {
  final authService = ref.read(authServiceProvider);
  final id = await authService.getSavedSeniorId();
  if (id != null) {
    await authService.ensureClaimed(id);
  }
  return id;
});
