import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Whether this senior has already seen the welcome guide. Keyed per senior so
/// a new person on a shared device still gets the guide once.
final onboardingSeenProvider =
    FutureProvider.family<bool, String>((ref, seniorId) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('onboarding_seen_$seniorId') ?? false;
});

/// Marks the welcome guide as seen for [seniorId] and refreshes the gate.
Future<void> markOnboardingSeen(WidgetRef ref, String seniorId) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('onboarding_seen_$seniorId', true);
  ref.invalidate(onboardingSeenProvider(seniorId));
}
