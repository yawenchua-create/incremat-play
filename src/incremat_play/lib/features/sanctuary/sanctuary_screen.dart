import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../l10n/app_localizations.dart';
import '../../models/pet.dart';
import '../../providers/senior_provider.dart';

/// The SANCTUARY — a gallery of every pet the senior has hatched. Lets them
/// browse their collection, see which species they've discovered, and pick the
/// active pet. Read-only celebration of progress (the reward for consistency).
class SanctuaryScreen extends ConsumerWidget {
  const SanctuaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final activePet = ref.watch(activePetProvider);
    final hatchedPets = ref.watch(hatchedPetsProvider);
    final selectedPetId = ref.watch(selectedPetIdProvider);
    final discoveredSpecies = hatchedPets
        .where((p) => p.species != null)
        .map((p) => p.species!)
        .toSet();
    // Highest stage reached per species — anything beyond this stays secret.
    final maxStage = maxStageReachedBySpecies(hatchedPets);

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Text(AppLocalizations.of(context).sanctuaryTitle,
                  style: AppTextStyles.displayMedium),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
              child: Text(
                AppLocalizations.of(context).sanctuarySubtitle,
                style: AppTextStyles.bodyMedium.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.55)),
              ),
            ),
          ),

          // ── Section 1: Active Lineage ──────────────────────────────────
          SliverToBoxAdapter(
            child: _SectionHeader(label: AppLocalizations.of(context).activeLineage),
          ),

          // Pet selector (only visible when 2+ hatched pets)
          if (hatchedPets.length > 1)
            SliverToBoxAdapter(
              child: _PetSelector(
                pets: hatchedPets,
                selectedId:
                    selectedPetId ?? (hatchedPets.isNotEmpty ? hatchedPets.first.id : null),
                onSelect: (id) =>
                    ref.read(selectedPetIdProvider.notifier).state = id,
              ),
            ),

          SliverToBoxAdapter(
            child: activePet != null
                ? _ActiveLineage(
                    pet: activePet,
                    maxStageReached:
                        maxStage[activePet.species] ?? activePet.stage.index,
                  )
                : _EmptyLineage(),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),

          // ── Section 2: Discoveries ─────────────────────────────────────
          SliverToBoxAdapter(
            child: _SectionHeader(label: AppLocalizations.of(context).discoveries),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverGrid(
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                mainAxisExtent: 220,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final species = PetSpecies.values[i];
                  final found = discoveredSpecies.contains(species);
                  final reached = maxStage[species] ?? -1;
                  return GestureDetector(
                    onTap: () => _showDiscoverySheet(
                        context, species, found, reached, activePet),
                    child: _DiscoveryCard(
                        species: species,
                        discovered: found,
                        maxStageReached: reached),
                  );
                },
                childCount: PetSpecies.values.length,
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  void _showDiscoverySheet(
    BuildContext context,
    PetSpecies species,
    bool discovered,
    int maxStageReached,
    Pet? activePet,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DiscoveryDetailSheet(
        species: species,
        discovered: discovered,
        maxStageReached: maxStageReached,
        activePet: activePet,
      ),
    );
  }
}

// ── Pet selector strip ────────────────────────────────────────────────────────

class _PetSelector extends StatelessWidget {
  final List<Pet> pets;
  final String? selectedId;
  final ValueChanged<String> onSelect;

  const _PetSelector({
    required this.pets,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context).chooseCompanion,
            style: AppTextStyles.caption.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.55),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 88,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: pets.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                final pet = pets[i];
                final isSelected = pet.id == selectedId;
                final ord = speciesOrdinal(pet, pets);
                return GestureDetector(
                  onTap: () => onSelect(pet.id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 74,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.sageGreen.withValues(alpha: 0.14)
                          : scheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.sageGreen
                            : scheme.onSurface.withValues(alpha: 0.1),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        pet.species != null
                            ? Image.asset(
                                pet.species!.imagePath(pet.stage),
                                width: 48,
                                height: 48,
                                fit: BoxFit.contain,
                              )
                            : Icon(Icons.egg_outlined,
                                size: 36,
                                color: scheme.onSurface
                                    .withValues(alpha: 0.4)),
                        const SizedBox(height: 4),
                        Text(
                          // Append "#N" so two of the same species are distinct.
                          (pet.species?.stageName(pet.stage) ?? '???') +
                              (ord.count > 1 ? '  #${ord.index}' : ''),
                          style: AppTextStyles.caption.copyWith(
                            fontSize: 11,
                            color: isSelected
                                ? AppColors.sageGreen
                                : scheme.onSurface.withValues(alpha: 0.6),
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w400,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Discovery detail bottom sheet ─────────────────────────────────────────────

class _DiscoveryDetailSheet extends StatelessWidget {
  final PetSpecies species;
  final bool discovered;
  final int maxStageReached;
  final Pet? activePet;

  const _DiscoveryDetailSheet({
    required this.species,
    required this.discovered,
    required this.maxStageReached,
    required this.activePet,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    const stages = [PetStage.baby, PetStage.young, PetStage.adult];
    final isSameSpecies = activePet?.species == species;
    final unlockedCount =
        stages.where((s) => s.index <= maxStageReached).length;
    // Title shows the highest evolution you've actually unlocked — never the
    // adult name before you've earned it.
    final titleName = maxStageReached >= 0
        ? species.stageName(PetStage.values[maxStageReached])
        : '???';

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            // Drag handle
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: scheme.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          discovered ? titleName : '???',
                          style: AppTextStyles.headlineLarge.copyWith(
                            color: discovered
                                ? AppColors.gold
                                : scheme.onSurface.withValues(alpha: 0.4),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          discovered
                              ? l.evolutionsUnlocked(
                                  species.label, unlockedCount, stages.length)
                              : l.undiscovered,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: discovered
                                ? AppColors.sageGreen
                                : scheme.onSurface.withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!discovered)
                    Icon(Icons.lock_outline_rounded,
                        size: 32,
                        color: scheme.onSurface.withValues(alpha: 0.25)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Divider(
                height: 24,
                indent: 24,
                endIndent: 24,
                color: scheme.onSurface.withValues(alpha: 0.08)),
            // Stages list
            Expanded(
              child: ListView.separated(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                itemCount: stages.length,
                separatorBuilder: (_, _) => const SizedBox(height: 16),
                itemBuilder: (_, i) {
                  final stage = stages[i];
                  // Revealed only once this evolution has been unlocked by any
                  // companion of this species.
                  final unlocked = stage.index <= maxStageReached;
                  final reached = isSameSpecies &&
                      activePet!.stage.index >= stage.index;
                  final isCurrent =
                      isSameSpecies && activePet!.stage == stage;
                  return _StageDetailRow(
                    species: species,
                    stage: stage,
                    unlocked: unlocked,
                    reached: reached,
                    isCurrent: isCurrent,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StageDetailRow extends StatelessWidget {
  final PetSpecies species;
  final PetStage stage;
  final bool unlocked;
  final bool reached;
  final bool isCurrent;

  const _StageDetailRow({
    required this.species,
    required this.stage,
    required this.unlocked,
    required this.reached,
    required this.isCurrent,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCurrent
            ? AppColors.gold.withValues(alpha: 0.08)
            : scheme.onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: isCurrent
            ? Border.all(color: AppColors.gold.withValues(alpha: 0.3))
            : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 88,
            height: 88,
            child: unlocked
                ? Image.asset(
                    species.imagePath(stage),
                    fit: BoxFit.contain,
                  )
                : ColorFiltered(
                    colorFilter: const ColorFilter.matrix(<double>[
                      0.2126, 0.7152, 0.0722, 0, 0,
                      0.2126, 0.7152, 0.0722, 0, 0,
                      0.2126, 0.7152, 0.0722, 0, 0,
                      0,      0,      0,      1, 0,
                    ]),
                    child: Opacity(
                      opacity: 0.3,
                      child: Image.asset(
                        species.imagePath(stage),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        unlocked ? species.stageName(stage) : '???',
                        style: AppTextStyles.headlineSmall.copyWith(
                          color: isCurrent
                              ? AppColors.gold
                              : unlocked
                                  ? null
                                  : scheme.onSurface.withValues(alpha: 0.35),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isCurrent) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          l.nowBadge,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.gold,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ] else if (reached) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.check_circle_rounded,
                          size: 16, color: AppColors.sageGreen),
                    ] else if (!unlocked) ...[
                      const SizedBox(width: 8),
                      Icon(Icons.lock_outline_rounded,
                          size: 16,
                          color: scheme.onSurface.withValues(alpha: 0.3)),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  unlocked
                      ? species.stageTagline(stage)
                      : l.reachToReveal,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: unlocked
                        ? scheme.onSurface.withValues(alpha: 0.6)
                        : scheme.onSurface.withValues(alpha: 0.35),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.sageGreen, AppColors.forest],
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: AppTextStyles.labelLarge.copyWith(
              letterSpacing: 1.4,
              color: AppColors.sageGreen,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Active Lineage ────────────────────────────────────────────────────────────

class _ActiveLineage extends StatelessWidget {
  final Pet pet;
  final int maxStageReached;
  const _ActiveLineage({required this.pet, required this.maxStageReached});

  @override
  Widget build(BuildContext context) {
    const stages = [PetStage.baby, PetStage.young, PetStage.adult];
    return Column(
      children: [
        for (int i = 0; i < stages.length; i++)
          _LineageRow(
            pet: pet,
            stage: stages[i],
            isLast: i == stages.length - 1,
            unlocked: stages[i].index <= maxStageReached,
          ),
      ],
    );
  }
}

class _LineageRow extends StatelessWidget {
  final Pet pet;
  final PetStage stage;
  final bool isLast;
  final bool unlocked;

  const _LineageRow({
    required this.pet,
    required this.stage,
    required this.isLast,
    required this.unlocked,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final isReached = pet.stage.index >= stage.index;
    final isCurrent = pet.stage == stage;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Timeline indicator
            SizedBox(
              width: 28,
              child: Column(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCurrent
                          ? AppColors.gold
                          : isReached
                              ? AppColors.sageGreen
                              : Colors.transparent,
                      border: Border.all(
                        color: isCurrent
                            ? AppColors.gold
                            : isReached
                                ? AppColors.sageGreen
                                : scheme.onSurface.withValues(alpha: 0.22),
                        width: 2,
                      ),
                    ),
                    child: isReached && !isCurrent
                        ? const Icon(Icons.check, size: 12, color: Colors.white)
                        : null,
                  ),
                  if (!isLast)
                    Expanded(
                      child: Center(
                        child: Container(
                          width: 2,
                          color: isReached
                              ? AppColors.sageGreen
                              : scheme.onSurface.withValues(alpha: 0.18),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Stage card
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? AppColors.gold.withValues(alpha: 0.08)
                        : scheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: isCurrent
                        ? Border.all(
                            color: AppColors.gold.withValues(alpha: 0.35))
                        : null,
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 120,
                        height: 120,
                        child: pet.species != null
                            ? isReached
                                ? Image.asset(
                                    pet.species!.imagePath(stage),
                                    fit: BoxFit.contain,
                                  )
                                : ColorFiltered(
                                    colorFilter: const ColorFilter.matrix(
                                        <double>[
                                      0.2126, 0.7152, 0.0722, 0, 0,
                                      0.2126, 0.7152, 0.0722, 0, 0,
                                      0.2126, 0.7152, 0.0722, 0, 0,
                                      0,      0,      0,      1, 0,
                                    ]),
                                    child: Opacity(
                                      opacity: 0.4,
                                      child: Image.asset(
                                        pet.species!.imagePath(stage),
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  )
                            : Icon(Icons.pets,
                                size: 56,
                                color: isReached
                                    ? AppColors.sageGreen
                                    : scheme.onSurface.withValues(alpha: 0.25)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              unlocked
                                  ? (pet.species?.stageName(stage) ??
                                      stage.label)
                                  : '???',
                              style: AppTextStyles.headlineSmall.copyWith(
                                color: isCurrent
                                    ? AppColors.gold
                                    : unlocked
                                        ? null
                                        : scheme.onSurface
                                            .withValues(alpha: 0.4),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              unlocked && pet.species != null
                                  ? pet.species!.stageTagline(stage)
                                  : l.futureEvolution,
                              style: AppTextStyles.caption.copyWith(
                                color: isReached
                                    ? scheme.onSurface.withValues(alpha: 0.55)
                                    : scheme.onSurface.withValues(alpha: 0.35),
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 6),
                            if (isCurrent && stage != PetStage.adult) ...[
                              LinearProgressIndicator(
                                value: pet.exp / stage.expToNext,
                                backgroundColor:
                                    scheme.onSurface.withValues(alpha: 0.12),
                                valueColor: const AlwaysStoppedAnimation(
                                    AppColors.gold),
                                borderRadius: BorderRadius.circular(3),
                                minHeight: 6,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                l.expBadge(pet.exp, stage.expToNext),
                                style: AppTextStyles.caption.copyWith(
                                    color: scheme.onSurface
                                        .withValues(alpha: 0.6)),
                              ),
                            ] else if (isCurrent &&
                                stage == PetStage.adult) ...[
                              Text(
                                l.fullyGrownLower,
                                style: AppTextStyles.bodyMedium
                                    .copyWith(color: AppColors.gold),
                              ),
                            ] else if (isReached) ...[
                              Row(
                                children: [
                                  const Icon(Icons.check_circle_rounded,
                                      size: 14, color: AppColors.sageGreen),
                                  const SizedBox(width: 4),
                                  Text(
                                    l.evolvedShort,
                                    style: AppTextStyles.caption.copyWith(
                                        color: AppColors.sageGreen),
                                  ),
                                ],
                              ),
                            ] else ...[
                              Text(
                                l.notYetReached,
                                style: AppTextStyles.caption.copyWith(
                                    color: scheme.onSurface
                                        .withValues(alpha: 0.38)),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyLineage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(Icons.egg_outlined,
                size: 40, color: scheme.onSurface.withValues(alpha: 0.2)),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                AppLocalizations.of(context).hatchFirstEgg,
                style: AppTextStyles.bodyMedium.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.55)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Discoveries grid ──────────────────────────────────────────────────────────

class _DiscoveryCard extends StatelessWidget {
  final PetSpecies species;
  final bool discovered;
  final int maxStageReached;
  const _DiscoveryCard({
    required this.species,
    required this.discovered,
    required this.maxStageReached,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Show the highest evolution unlocked so far — not the adult by default,
    // so later stages stay a surprise.
    final shownStage = maxStageReached >= 0
        ? PetStage.values[maxStageReached]
        : PetStage.adult;
    const totalStages = 3; // baby, young, adult
    final unlockedCount = (maxStageReached + 1).clamp(0, totalStages);

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 140,
            height: 140,
            child: discovered
                ? Image.asset(
                    species.imagePath(shownStage),
                    fit: BoxFit.contain,
                  )
                : ColorFiltered(
                    colorFilter: const ColorFilter.matrix(<double>[
                      0.2126, 0.7152, 0.0722, 0, 0,
                      0.2126, 0.7152, 0.0722, 0, 0,
                      0.2126, 0.7152, 0.0722, 0, 0,
                      0,      0,      0,      1, 0,
                    ]),
                    child: Opacity(
                      opacity: 0.35,
                      child: Image.asset(
                        species.imagePath(PetStage.adult),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              discovered ? species.stageName(shownStage) : '???',
              style: AppTextStyles.labelLarge.copyWith(
                color: discovered
                    ? scheme.onSurface
                    : scheme.onSurface.withValues(alpha: 0.4),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (discovered) ...[
            const SizedBox(height: 2),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                AppLocalizations.of(context)
                    .speciesProgress(species.label, unlockedCount, totalStages),
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.sageGreen,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ] else ...[
            const SizedBox(height: 2),
            Icon(Icons.lock_outline_rounded,
                size: 16, color: scheme.onSurface.withValues(alpha: 0.25)),
          ],
        ],
      ),
    );
  }
}
