import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../models/pet.dart';
import '../../providers/senior_provider.dart';

class SanctuaryScreen extends ConsumerWidget {
  const SanctuaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final petsAsync = ref.watch(petsProvider);

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Text('Sanctuary', style: AppTextStyles.displayMedium),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
              child: Text(
                'All your beloved companions',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.subtleText),
              ),
            ),
          ),
          petsAsync.when(
            data: (pets) {
              final hatched = pets.where((p) => p.isHatched).toList();
              if (hatched.isEmpty) {
                return SliverToBoxAdapter(
                  child: _EmptySanctuary(),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverGrid(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.85,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => _SanctuaryPetCard(pet: hatched[i]),
                    childCount: hatched.length,
                  ),
                ),
              );
            },
            loading: () => const SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child:
                      CircularProgressIndicator(color: AppColors.sageGreen),
                ),
              ),
            ),
            error: (_, _) => const SliverToBoxAdapter(child: SizedBox.shrink()),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

class _SanctuaryPetCard extends StatelessWidget {
  final Pet pet;
  const _SanctuaryPetCard({required this.pet});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.espresso.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: pet.species != null
                  ? Image.asset(
                      pet.species!.imagePath(pet.stage),
                      fit: BoxFit.contain,
                    )
                  : const Icon(Icons.pets, size: 56, color: AppColors.sageGreen),
            ),
            const SizedBox(height: 10),
            Text(
              pet.species?.label ?? 'Pet',
              style: AppTextStyles.labelLarge,
              textAlign: TextAlign.center,
            ),
            Text(
              pet.stage.label,
              style: AppTextStyles.caption,
            ),
            const SizedBox(height: 8),
            if (pet.stage != PetStage.adult)
              LinearProgressIndicator(
                value: pet.exp / pet.stage.expToNext,
                backgroundColor: AppColors.lightSage,
                valueColor: const AlwaysStoppedAnimation(AppColors.gold),
                minHeight: 5,
                borderRadius: BorderRadius.circular(3),
              )
            else
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Max level',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.gold),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EmptySanctuary extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            const Icon(Icons.park_outlined,
                size: 56, color: AppColors.lightSage),
            const SizedBox(height: 16),
            Text('No companions yet', style: AppTextStyles.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Hatch your first egg to populate\nyour sanctuary!',
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
