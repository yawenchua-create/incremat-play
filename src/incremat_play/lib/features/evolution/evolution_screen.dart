import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../models/pet.dart';

class EvolutionScreen extends StatefulWidget {
  final Pet pet;
  final PetStage previousStage;

  const EvolutionScreen({
    super.key,
    required this.pet,
    required this.previousStage,
  });

  @override
  State<EvolutionScreen> createState() => _EvolutionScreenState();
}

class _EvolutionScreenState extends State<EvolutionScreen>
    with SingleTickerProviderStateMixin {
  late final ConfettiController _confetti;
  late final AnimationController _scale;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 4));
    _scale = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleAnim = CurvedAnimation(parent: _scale, curve: Curves.elasticOut);
    Future.delayed(const Duration(milliseconds: 200), () {
      _confetti.play();
      _scale.forward();
    });
  }

  @override
  void dispose() {
    _confetti.dispose();
    _scale.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final species = widget.pet.species;
    final stageName = widget.pet.stage.label;

    return Scaffold(
      backgroundColor: AppColors.warmCream,
      body: Stack(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirectionality: BlastDirectionality.explosive,
              colors: const [
                AppColors.sageGreen,
                AppColors.gold,
                AppColors.lightSage,
                AppColors.terracotta,
              ],
              numberOfParticles: 40,
              gravity: 0.2,
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Amazing!',
                    style: AppTextStyles.displayLarge.copyWith(
                      color: AppColors.gold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your pet has evolved!',
                    style: AppTextStyles.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  ScaleTransition(
                    scale: _scaleAnim,
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        color: AppColors.lightSage.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: AppColors.gold, width: 3),
                      ),
                      child: Center(
                        child: Text(
                          species?.emoji ?? '🥚',
                          style: const TextStyle(fontSize: 80),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    '${widget.previousStage.label} → $stageName',
                    style: AppTextStyles.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    species != null
                        ? '${species.label} is now a $stageName!'
                        : 'Your pet grew up!',
                    style: AppTextStyles.headlineLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 56),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Wonderful!', style: AppTextStyles.buttonText),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
