import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show DeviceOrientation, SystemChrome;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'features/home/home_screen.dart';
import 'features/login/login_screen.dart';
import 'providers/accessibility_provider.dart';
import 'providers/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const ProviderScope(child: IncrematPlayApp()));
}

class IncrematPlayApp extends ConsumerWidget {
  const IncrematPlayApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(accessibilityProvider.select((s) => s.themeMode));

    return MaterialApp(
      title: 'IncreMat Play',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      home: const _AppGate(),
    );
  }
}

class _AppGate extends ConsumerWidget {
  const _AppGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textScale = ref.watch(accessibilityProvider.select((s) => s.textScale));
    final authAsync = ref.watch(authStateProvider);
    final seniorIdAsync = ref.watch(seniorIdProvider);

    final child = authAsync.when(
      data: (user) {
        if (user == null) return const LoginScreen();
        return seniorIdAsync.when(
          data: (id) {
            if (id == null) return const LoginScreen();
            return const HomeScreen();
          },
          loading: () => const _SplashScreen(),
          error: (_, _) => const LoginScreen(),
        );
      },
      loading: () => const _SplashScreen(),
      error: (_, _) => const LoginScreen(),
    );

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(textScale),
      ),
      child: child,
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
