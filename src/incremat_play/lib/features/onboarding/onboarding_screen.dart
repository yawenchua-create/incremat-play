import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/onboarding_provider.dart';

/// A short, friendly welcome guide shown the first time a senior logs in.
/// Deliberately large, simple, and one idea per page.
class OnboardingScreen extends ConsumerStatefulWidget {
  final String seniorId;
  const OnboardingScreen({super.key, required this.seniorId});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<_Step> _steps(AppLocalizations l) => [
        _Step(
          icon: Icons.eco_rounded,
          color: AppColors.sageGreen,
          title: l.obWelcomeTitle,
          body: l.obWelcomeBody,
        ),
        _Step(
          icon: Icons.event_seat_rounded,
          color: AppColors.forest,
          title: l.obMoveTitle,
          body: l.obMoveBody,
        ),
        _Step(
          icon: Icons.egg_alt_rounded,
          color: AppColors.gold,
          title: l.obPetTitle,
          body: l.obPetBody,
        ),
        _Step(
          icon: Icons.track_changes_rounded,
          color: AppColors.sageGreen,
          title: l.obGoalTitle,
          body: l.obGoalBody,
        ),
      ];

  Future<void> _finish() async {
    await markOnboardingSeen(ref, widget.seniorId);
    // If it was opened again later (pushed over Home), close it; on first login
    // it's shown by the gate, which swaps to Home once it's marked seen.
    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  void _next(int count) {
    if (_page >= count - 1) {
      _finish();
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final steps = _steps(l);
    final isLast = _page == steps.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip — small, top-right, for anyone who'd rather jump in.
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 12, 0),
                child: TextButton(
                  onPressed: _finish,
                  child: Text(l.obSkip,
                      style: AppTextStyles.labelLarge
                          .copyWith(color: AppColors.subtleText)),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: steps.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) => _StepView(step: steps[i]),
              ),
            ),
            // Page dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < steps.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _page ? 26 : 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: i == _page
                          ? AppColors.sageGreen
                          : AppColors.sageGreen.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
              child: SizedBox(
                width: double.infinity,
                height: 64,
                child: ElevatedButton(
                  onPressed: () => _next(steps.length),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.sageGreen,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32)),
                  ),
                  child: Text(isLast ? l.obStart : l.obNext,
                      style: AppTextStyles.buttonText.copyWith(fontSize: 22)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Step {
  final IconData icon;
  final Color color;
  final String title;
  final String body;
  const _Step({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });
}

class _StepView extends StatelessWidget {
  final _Step step;
  const _StepView({required this.step});

  @override
  Widget build(BuildContext context) {
    // Scroll-safe: content centers when there's room, but scrolls instead of
    // overflowing on short screens or when the senior's text-scale is large.
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    color: step.color.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(step.icon, size: 84, color: step.color),
                ),
                const SizedBox(height: 40),
                Text(
                  step.title,
                  style: AppTextStyles.displayMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  step.body,
                  style: AppTextStyles.bodyLarge
                      .copyWith(color: AppColors.subtleText),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
