import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../l10n/app_localizations.dart';

/// Full-screen congratulations shown when a Duet goal is reached (coop) or a
/// match is won (versus). Confetti, a bouncing badge and a celebratory haptic
/// make the moment feel special; one large button dismisses it back to the
/// live session. Mirrors the egg/evolution celebration style.
class DuetCelebrationScreen extends StatefulWidget {
  final String title;
  final String message;
  final IconData icon;
  final Color accent;

  const DuetCelebrationScreen({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.emoji_events_rounded,
    this.accent = AppColors.gold,
  });

  @override
  State<DuetCelebrationScreen> createState() => _DuetCelebrationScreenState();
}

class _DuetCelebrationScreenState extends State<DuetCelebrationScreen>
    with TickerProviderStateMixin {
  late final ConfettiController _confetti;
  late final AnimationController _scaleCtrl;
  late final Animation<double> _scaleAnim;
  late final AnimationController _floatCtrl;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 4));
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleAnim = CurvedAnimation(parent: _scaleCtrl, curve: Curves.elasticOut);
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    Future.delayed(const Duration(milliseconds: 150), () {
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      _confetti.play();
      _scaleCtrl.forward();
    });
  }

  @override
  void dispose() {
    _confetti.dispose();
    _scaleCtrl.dispose();
    _floatCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Stack(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirectionality: BlastDirectionality.explosive,
              colors: const [
                AppColors.gold,
                AppColors.sageGreen,
                AppColors.lightSage,
                AppColors.terracotta,
              ],
              numberOfParticles: 40,
              gravity: 0.2,
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                child: ConstrainedBox(
                  constraints:
                      BoxConstraints(minHeight: constraints.maxHeight - 48),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ScaleTransition(
                        scale: _scaleAnim,
                        child: AnimatedBuilder(
                          animation: _floatCtrl,
                          builder: (_, child) => Transform.translate(
                            offset: Offset(0, -8 + 16 * _floatCtrl.value),
                            child: child,
                          ),
                          child: Container(
                            width: 184,
                            height: 184,
                            decoration: BoxDecoration(
                              color: widget.accent.withValues(alpha: 0.16),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(widget.icon,
                                size: 100, color: widget.accent),
                          ),
                        ),
                      ),
                      const SizedBox(height: 36),
                      Text(
                        widget.title,
                        style: AppTextStyles.displayLarge
                            .copyWith(color: widget.accent),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.message,
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 44),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(AppLocalizations.of(context).wonderful,
                              style: AppTextStyles.buttonText),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
