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
    final prevName = species?.stageName(widget.previousStage)
        ?? widget.previousStage.label;
    final newName = species?.stageName(widget.pet.stage)
        ?? widget.pet.stage.label;

    return Scaffold(
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
                      Text(
                        'Amazing!',
                        style: AppTextStyles.displayLarge.copyWith(
                            color: AppColors.gold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '$prevName evolved into $newName!',
                        style: AppTextStyles.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 48),
                      ScaleTransition(
                        scale: _scaleAnim,
                        child: species != null
                            ? Image.asset(
                                species.imagePath(widget.pet.stage),
                                width: 200,
                                height: 200,
                                fit: BoxFit.contain,
                              )
                            : const Icon(Icons.pets,
                                size: 160, color: AppColors.sageGreen),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        newName,
                        style: AppTextStyles.headlineLarge.copyWith(
                            color: AppColors.gold),
                        textAlign: TextAlign.center,
                      ),
                      if (species != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          species.stageTagline(widget.pet.stage),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.6),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      const SizedBox(height: 52),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text('Wonderful!',
                            style: AppTextStyles.buttonText),
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
