import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../l10n/app_localizations.dart';

/// Full-screen celebration shown when the user is awarded a new egg.
class EggAwardScreen extends StatefulWidget {
  const EggAwardScreen({super.key});

  @override
  State<EggAwardScreen> createState() => _EggAwardScreenState();
}

// `with TickerProviderStateMixin` provides the "ticker" that drives animations
// (it fires once per screen frame). It's required whenever a State owns one or
// more AnimationControllers — as the celebration screens do for their bounce/
// confetti effects. (Use SingleTickerProviderStateMixin for exactly one.)
class _EggAwardScreenState extends State<EggAwardScreen>
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
          // Egg, text and button in one centred, overflow-safe column.
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 24),
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
                          child: const _EggImage(size: 200),
                        ),
                      ),
                      const SizedBox(height: 36),
                      Text(
                        AppLocalizations.of(context).youEarnedEgg,
                        style: AppTextStyles.displayLarge
                            .copyWith(color: AppColors.gold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppLocalizations.of(context).companionWaiting,
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.7),
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

// Single static egg frame (top-left quadrant of the 2×2 spritesheet).
class _EggImage extends StatelessWidget {
  final double size;
  const _EggImage({required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: ClipRect(
        child: OverflowBox(
          maxWidth: size * 2,
          maxHeight: size * 2,
          alignment: const Alignment(-1.0, -1.0),
          child: Image.asset(
            'assets/pets/egg.png',
            width: size * 2,
            height: size * 2,
            fit: BoxFit.fill,
          ),
        ),
      ),
    );
  }
}
