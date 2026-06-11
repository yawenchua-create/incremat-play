import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/mat_ble_service.dart';
import 'auth_provider.dart';
import 'senior_provider.dart';

/// One BLE client for the whole app lifetime.
final matBleServiceProvider = Provider<MatBleService>((ref) {
  final service = MatBleService();
  ref.onDispose(service.dispose);
  return service;
});

/// Connection state of the phone to the mat, seeded with the current value so
/// watchers get it immediately (flutter_blue_plus streams don't replay).
final matStateProvider = StreamProvider<MatConnState>((ref) async* {
  final service = ref.watch(matBleServiceProvider);
  yield service.state;
  yield* service.stateStream;
});

/// Live cumulative rep count straight from the mat (no Firebase hop).
final matRepCountProvider = StreamProvider<int>((ref) async* {
  final service = ref.watch(matBleServiceProvider);
  yield service.lastReps;
  yield* service.repCountStream;
});

/// Unified live reps for *this* senior: prefers the direct BLE reading when the
/// mat is connected (instant), and falls back to the Firebase-mirrored value
/// (published by the caregiver app) when it isn't.
final myLiveProvider = Provider<({int reps, bool live})>((ref) {
  final connected =
      ref.watch(matStateProvider).valueOrNull == MatConnState.connected;
  if (connected) {
    final reps = ref.watch(matRepCountProvider).valueOrNull ?? 0;
    return (reps: reps, live: true);
  }
  final fb = ref.watch(liveSessionProvider).valueOrNull;
  final live = fb?.isLive ?? false;
  return (reps: live ? fb!.repCount : 0, live: live);
});

/// Keep-alive side-effect: whenever a rep arrives over BLE, mirror it to
/// Firestore so remote viewers (caregiver, competitive/duet partner) stay in
/// sync. Watch this somewhere always-mounted (the home tab) to activate it.
final liveMirrorProvider = Provider<void>((ref) {
  final seniorId = ref.watch(seniorIdProvider).valueOrNull;
  final service = ref.watch(seniorServiceProvider);
  ref.listen<AsyncValue<int>>(matRepCountProvider, (_, next) {
    final reps = next.valueOrNull;
    final connected =
        ref.read(matStateProvider).valueOrNull == MatConnState.connected;
    if (seniorId != null && reps != null && connected) {
      service.publishLive(seniorId, reps);
    }
  });
});
