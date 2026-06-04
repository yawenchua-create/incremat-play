import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../l10n/app_localizations.dart';
import '../../models/pet.dart';
import '../../providers/senior_provider.dart';

enum _Phase { rocking, shaking, revealed }

// Background colour baked into the reveal videos. The hatching screen matches
// it so the video blends seamlessly into the page.
const Color _videoBgColor = Color(0xFFEFECE1);

// Per-species reveal animation. null = no video yet (use the static sprite).
String? _revealVideoAsset(PetSpecies? species) {
  switch (species) {
    case PetSpecies.otter:
      return 'assets/animations/otter.mp4';
    case PetSpecies.fox:
      return 'assets/animations/fox.mp4';
    case PetSpecies.tortoise:
      return 'assets/animations/tortoise.mp4';
    case PetSpecies.koi:
    case null:
      return null;
  }
}

class HatchingScreen extends ConsumerStatefulWidget {
  final Pet egg;
  final String seniorId;

  const HatchingScreen({
    super.key,
    required this.egg,
    required this.seniorId,
  });

  @override
  ConsumerState<HatchingScreen> createState() => _HatchingScreenState();
}

class _HatchingScreenState extends ConsumerState<HatchingScreen>
    with TickerProviderStateMixin {
  late final ConfettiController _confetti;
  late final AnimationController _rockCtrl;
  late final AnimationController _shakeCtrl;
  late final AnimationController _revealCtrl;

  late final Animation<double> _rockAnim;
  late final Animation<double> _shakeAnim;
  late final Animation<double> _revealAnim;

  _Phase _phase = _Phase.rocking;
  Pet? _hatchedPet;
  VideoPlayerController? _videoCtrl;

  @override
  void initState() {
    super.initState();

    _confetti = ConfettiController(duration: const Duration(seconds: 5));

    _rockCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _rockAnim = Tween<double>(begin: -0.07, end: 0.07).animate(
      CurvedAnimation(parent: _rockCtrl, curve: Curves.easeInOut),
    );
    _rockCtrl.repeat(reverse: true);

    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _shakeAnim = Tween<double>(begin: 0, end: 1).animate(_shakeCtrl);

    _revealCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _revealAnim =
        CurvedAnimation(parent: _revealCtrl, curve: Curves.elasticOut);

    Future.delayed(const Duration(milliseconds: 1600), _beginShake);
  }

  Future<void> _beginShake() async {
    if (!mounted) return;
    setState(() => _phase = _Phase.shaking);
    _rockCtrl.stop();

    // Run the hatch (write + read-back) alongside the shake animation.
    // _doHatch never throws, so we can never get stuck on the shaking phase.
    final hatchFuture = _doHatch();
    try {
      await _shakeCtrl.forward();
    } catch (_) {
      // Controller disposed mid-animation — ignore.
    }
    final hatched = await hatchFuture;

    if (!mounted) return;

    // Prepare the species reveal animation (if one exists for this species).
    await _initRevealVideo(hatched.species);

    if (!mounted) return;

    setState(() {
      _phase = _Phase.revealed;
      _hatchedPet = hatched;
    });
    _confetti.play();
    _revealCtrl.forward();
  }

  // Loads and starts the looping reveal video for the hatched species. Failures
  // are swallowed so the reveal always falls back to the static sprite.
  Future<void> _initRevealVideo(PetSpecies? species) async {
    final asset = _revealVideoAsset(species);
    if (asset == null) return;
    try {
      final ctrl = VideoPlayerController.asset(asset);
      await ctrl.initialize();
      await ctrl.setLooping(true);
      await ctrl.setVolume(0); // muted — looping audio would be jarring
      await ctrl.play();
      _videoCtrl = ctrl;
    } catch (_) {
      _videoCtrl?.dispose();
      _videoCtrl = null;
    }
  }

  // Performs the Firestore hatch and reads the result back. Always resolves —
  // on any failure it falls back to the original egg so the UI can proceed.
  Future<Pet> _doHatch() async {
    try {
      final svc = ref.read(petServiceProvider);
      await svc.hatchEgg(widget.seniorId, widget.egg.id);
      final updated = await svc.getPet(widget.seniorId, widget.egg.id);
      if (updated != null) return updated;
    } catch (_) {
      // Permission/network error — fall through to the egg fallback.
    }
    return widget.egg;
  }

  @override
  void dispose() {
    _confetti.dispose();
    _rockCtrl.dispose();
    _shakeCtrl.dispose();
    _revealCtrl.dispose();
    _videoCtrl?.dispose();
    super.dispose();
  }

  double _shakeOffset(double t) =>
      sin(t * pi * 10) * 18.0 * (1.0 - t);

  @override
  Widget build(BuildContext context) {
    // When a video is playing use the video's own background so it blends in.
    final bg = _videoCtrl != null ? _videoBgColor : null;
    return Scaffold(
      backgroundColor: bg,
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
              numberOfParticles: 50,
              gravity: 0.2,
            ),
          ),
          SafeArea(
            child: _phase == _Phase.revealed
                ? _buildRevealLayout()
                : _buildPreRevealLayout(),
          ),
        ],
      ),
    );
  }

  // Pre-reveal: egg dead-centre, title floating in the top third.
  Widget _buildPreRevealLayout() {
    return Stack(
      children: [
        Center(child: _buildEgg()),
        Positioned(
          top: 48,
          left: 28,
          right: 28,
          child: Column(
            children: [
              Text(
                _phase == _Phase.shaking
                    ? AppLocalizations.of(context).itsHatching
                    : AppLocalizations.of(context).eggIsReady,
                style: AppTextStyles.displayLarge
                    .copyWith(color: AppColors.gold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _phase == _Phase.shaking
                    ? AppLocalizations.of(context).somethingComingOut
                    : AppLocalizations.of(context).getReady,
                style: AppTextStyles.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Reveal: vertically-centred, scrollable for large text sizes.
  Widget _buildRevealLayout() {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [_buildReveal()],
          ),
        ),
      ),
    );
  }

  Widget _buildEgg() {
    const egg = _StaticEgg(size: 200);
    if (_phase == _Phase.shaking) {
      return AnimatedBuilder(
        animation: _shakeAnim,
        builder: (_, child) => Transform.translate(
          offset: Offset(_shakeOffset(_shakeAnim.value), 0),
          child: child,
        ),
        child: egg,
      );
    }
    return AnimatedBuilder(
      animation: _rockAnim,
      // Pivot at the base so the egg wobbles like it's resting on the ground.
      builder: (_, child) => Transform.rotate(
        angle: _rockAnim.value,
        alignment: Alignment.bottomCenter,
        child: child,
      ),
      child: egg,
    );
  }

  Widget _buildReveal() {
    final pet = _hatchedPet;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          AppLocalizations.of(context).itHatched,
          style: AppTextStyles.displayLarge.copyWith(color: AppColors.gold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 48),
        ScaleTransition(
          scale: _revealAnim,
          child: _buildRevealVisual(pet),
        ),
        const SizedBox(height: 24),
        if (pet?.species != null) ...[
          // Incremon stage name
          Text(
            pet!.species!.stageName(PetStage.baby),
            style: AppTextStyles.headlineLarge.copyWith(color: AppColors.gold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            pet.species!.label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.sageGreen,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              pet.species!.stageTagline(PetStage.baby),
              style: AppTextStyles.bodySmall.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6)),
              textAlign: TextAlign.center,
            ),
          ),
        ] else
          Text(
            AppLocalizations.of(context).newCompanionAppeared,
            style: AppTextStyles.bodyLarge,
            textAlign: TextAlign.center,
          ),
        const SizedBox(height: 40),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppLocalizations.of(context).letsGo, style: AppTextStyles.buttonText),
        ),
      ],
    );
  }

  // Plays the species reveal video when available, otherwise shows the static
  // baby sprite (e.g. koi, or if the video failed to load).
  Widget _buildRevealVisual(Pet? pet) {
    final ctrl = _videoCtrl;
    if (ctrl != null && ctrl.value.isInitialized) {
      // Compute the exact pixel dimensions that maintain the video's aspect
      // ratio at 336 px wide (= 240 × 1.4, giving 48 px side crop each side).
      // The container height = contentH - 1 so only the 1-px green decoder
      // line is hidden by the cream strip. No FittedBox involved so the crop
      // is correct for any aspect ratio.
      const contentW = 240.0 * 1.4; // 336 px
      final contentH =
          contentW * ctrl.value.size.height / ctrl.value.size.width;
      final containerH = contentH - 1;

      return SizedBox(
        width: 240,
        height: containerH,
        child: Stack(
          children: [
            ClipRect(
              child: OverflowBox(
                alignment: Alignment.topCenter,
                maxWidth: contentW,
                maxHeight: contentH,
                child: SizedBox(
                  width: contentW,
                  height: contentH,
                  child: VideoPlayer(ctrl),
                ),
              ),
            ),
            // Covers the 1-px green decoder line at the bottom of the frame.
            Positioned(
              left: 0, right: 0, bottom: 0, height: 1,
              child: ColoredBox(color: _videoBgColor),
            ),
          ],
        ),
      );
    }
    if (pet?.species != null) {
      return Image.asset(
        pet!.species!.imagePath(PetStage.baby),
        width: 220,
        height: 220,
        fit: BoxFit.contain,
      );
    }
    return const Icon(Icons.pets, size: 160, color: AppColors.sageGreen);
  }
}

// A single, stable egg frame (top-left quadrant of the 2×2 spritesheet).
// Motion is supplied by the parent's rock/shake transforms, which keeps the
// egg centred and steady instead of jittering between spritesheet frames.
class _StaticEgg extends StatelessWidget {
  final double size;
  const _StaticEgg({required this.size});

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
