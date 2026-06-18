import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show DeviceOrientation, SystemChrome;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'features/home/home_screen.dart';
import 'features/login/login_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'l10n/app_localizations.dart';
import 'providers/accessibility_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/onboarding_provider.dart';

/// Entry point of the Play (senior-facing) app. Same shape as the caregiver
/// app's main(): init bindings + Firebase, then runApp inside a ProviderScope.
/// The extra step here LOCKS the app to portrait — seniors hold the phone one
/// way, and a fixed orientation keeps the game UI predictable.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const ProviderScope(child: IncrematPlayApp()));
}

// Only watches themeMode — highContrast is applied below MaterialApp via Theme
// to avoid rebuilding MaterialApp and triggering GlobalKey ink renderer conflicts.
class IncrematPlayApp extends ConsumerWidget {
  const IncrematPlayApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode =
        ref.watch(accessibilityProvider.select((s) => s.themeMode));
    final locale = ref.watch(localeProvider);

    return MaterialApp(
      title: 'IncreMat Play',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const _AppGate(),
    );
  }
}

// Handles only accessibility settings. Child is const so the auth/screen
// subtree is never structurally rebuilt when textScale or highContrast change.
class _AppGate extends ConsumerStatefulWidget {
  const _AppGate();

  @override
  ConsumerState<_AppGate> createState() => _AppGateState();
}

class _AppGateState extends ConsumerState<_AppGate> {
  @override
  Widget build(BuildContext context) {
    final textScale =
        ref.watch(accessibilityProvider.select((s) => s.textScale));
    final highContrast =
        ref.watch(accessibilityProvider.select((s) => s.highContrast));
    final brightness = Theme.of(context).brightness;

    final hcTheme = highContrast
        ? (brightness == Brightness.dark
            ? AppTheme.dark(highContrast: true)
            : AppTheme.light(highContrast: true))
        : Theme.of(context);

    return Theme(
      data: hcTheme,
      child: MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
        ),
        child: const _AuthGate(),
      ),
    );
  }
}

// Const widget — Flutter reuses this element when _AppGateState rebuilds,
// preventing any GlobalKey conflicts in the mounted IndexedStack screens.
class _AuthGate extends ConsumerWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Gate purely on the saved senior ID. seniorIdProvider guarantees a Firebase
    // user exists when an ID is present, so we don't need to wait on the
    // authStateChanges() stream — waiting on it was what forced a second login.
    final seniorIdAsync = ref.watch(seniorIdProvider);

    return seniorIdAsync.when(
      data: (id) =>
          id == null ? const LoginScreen() : _PostLoginGate(seniorId: id),
      loading: () => const _SplashScreen(),
      error: (_, _) => const LoginScreen(),
    );
  }
}

// Shows the welcome guide on the very first login for this senior, then Home.
class _PostLoginGate extends ConsumerWidget {
  final String seniorId;
  const _PostLoginGate({required this.seniorId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seen = ref.watch(onboardingSeenProvider(seniorId));
    return seen.when(
      data: (hasSeen) =>
          hasSeen ? const HomeScreen() : OnboardingScreen(seniorId: seniorId),
      // Wait for the quick prefs read so Home never flashes before the guide.
      loading: () => const _SplashScreen(),
      error: (_, _) => const HomeScreen(),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(
          color: Color(0xFF8DA399),
        ),
      ),
    );
  }
}
