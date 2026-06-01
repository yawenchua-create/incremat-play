import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _ctrl = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final code = _ctrl.text.trim();
    if (code.isEmpty) return;
    setState(() { _isLoading = true; _error = null; });
    try {
      final error = await ref.read(authServiceProvider).signInWithJoinCode(code);
      if (!mounted) return;
      if (error == null) {
        ref.invalidate(seniorIdProvider);
      }
      setState(() { _isLoading = false; _error = error; });
    } catch (_) {
      if (!mounted) return;
      setState(() { _isLoading = false; _error = 'Something went wrong. Please try again.'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.warmCream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.lightSage.withValues(alpha: 0.4),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.eco,
                    size: 52,
                    color: AppColors.sageGreen,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Center(
                child: Text(
                  'IncreMat Play',
                  style: AppTextStyles.displayLarge,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Your daily exercise companion',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.subtleText,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 56),
              Text('Enter your play code', style: AppTextStyles.headlineSmall),
              const SizedBox(height: 8),
              Text(
                'Your caregiver will give you this code.',
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _ctrl,
                textCapitalization: TextCapitalization.characters,
                style: AppTextStyles.headlineLarge.copyWith(
                  letterSpacing: 4,
                ),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: 'ROSE-4821',
                  hintStyle: TextStyle(
                    color: AppColors.subtleText,
                    letterSpacing: 2,
                    fontSize: 20,
                  ),
                ),
                onSubmitted: (_) => _signIn(),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.terracotta.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: AppColors.terracotta, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _error!,
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.terracotta),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _signIn,
                child: _isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text('Get Started', style: AppTextStyles.buttonText),
              ),
              const SizedBox(height: 48),
              Center(
                child: Text(
                  'Ask your caregiver for your play code\nif you don\'t have one yet.',
                  style: AppTextStyles.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
