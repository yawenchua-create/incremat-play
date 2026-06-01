import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../models/pet.dart';
import '../../models/senior.dart';
import '../../providers/auth_provider.dart';
import '../../providers/senior_provider.dart';
import '../sanctuary/sanctuary_screen.dart';
import '../history/history_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _tab = 0;

  final _screens = const [
    _PlayTab(),
    SanctuaryScreen(),
    HistoryScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.warmCream,
      body: IndexedStack(index: _tab, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        backgroundColor: AppColors.cardSurface,
        indicatorColor: AppColors.lightSage.withValues(alpha: 0.5),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.park_outlined),
            selectedIcon: Icon(Icons.park),
            label: 'Sanctuary',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _PlayTab extends ConsumerWidget {
  const _PlayTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seniorAsync = ref.watch(seniorProvider);
    final petsAsync = ref.watch(petsProvider);

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: seniorAsync.when(
                data: (senior) => Text(
                  senior != null ? 'Hello, ${senior.name}!' : 'Hello!',
                  style: AppTextStyles.displayMedium,
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, _) => Text('Hello!', style: AppTextStyles.displayMedium),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
              child: Text(
                'Keep up your great work today!',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.subtleText),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: seniorAsync.when(
              data: (senior) => senior != null
                  ? _DailyProgressCard(senior: senior)
                  : const SizedBox.shrink(),
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(color: AppColors.sageGreen),
                ),
              ),
              error: (_, _) => const SizedBox.shrink(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
              child: Text('Your Pets', style: AppTextStyles.headlineSmall),
            ),
          ),
          petsAsync.when(
            data: (pets) {
              if (pets.isEmpty) {
                return SliverToBoxAdapter(
                  child: _EmptyPetsCard(),
                );
              }
              final active = pets.where((p) => p.isHatched).toList();
              final eggs = pets.where((p) => !p.isHatched).toList();
              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      if (i < active.length) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _PetCard(pet: active[i]),
                        );
                      }
                      final egg = eggs[i - active.length];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _EggCard(egg: egg),
                      );
                    },
                    childCount: active.length + eggs.length,
                  ),
                ),
              );
            },
            loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
            error: (_, _) => const SliverToBoxAdapter(child: SizedBox.shrink()),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

class _DailyProgressCard extends ConsumerWidget {
  final Senior senior;
  const _DailyProgressCard({required this.senior});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(sessionsProvider);
    return sessionsAsync.when(
      data: (sessions) {
        final today = DateTime.now();
        final todayReps = sessions
            .where((s) =>
                s.date.year == today.year &&
                s.date.month == today.month &&
                s.date.day == today.day)
            .fold(0, (sum, s) => sum + s.repCount);
        final progress = (todayReps / senior.dailyRepGoal).clamp(0.0, 1.0);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.cardSurface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.espresso.withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Today's Goal", style: AppTextStyles.headlineSmall),
                const SizedBox(height: 20),
                Row(
                  children: [
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 7,
                            backgroundColor: AppColors.lightSage,
                            valueColor: const AlwaysStoppedAnimation(
                                AppColors.sageGreen),
                            strokeCap: StrokeCap.round,
                          ),
                          Text(
                            '${(progress * 100).round()}%',
                            style: AppTextStyles.labelLarge
                                .copyWith(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: '$todayReps',
                                  style: AppTextStyles.statMedium,
                                ),
                                TextSpan(
                                  text: ' / ${senior.dailyRepGoal} reps',
                                  style: AppTextStyles.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            progress >= 1.0
                                ? 'Goal complete! Great job!'
                                : todayReps == 0
                                    ? 'Ready to start?'
                                    : 'Keep it up!',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: progress >= 1.0
                                  ? AppColors.sageGreen
                                  : AppColors.subtleText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: AppColors.lightSage,
                  valueColor:
                      const AlwaysStoppedAnimation(AppColors.sageGreen),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

class _PetCard extends StatelessWidget {
  final Pet pet;
  const _PetCard({required this.pet});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.lightSage.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: pet.species != null
                  ? Image.asset(
                      pet.species!.imagePath(pet.stage),
                      fit: BoxFit.cover,
                    )
                  : const Icon(Icons.pets, size: 32, color: AppColors.sageGreen),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pet.species?.label ?? 'Pet',
                  style: AppTextStyles.headlineSmall,
                ),
                Text(
                  pet.stage.label,
                  style: AppTextStyles.bodySmall,
                ),
                const SizedBox(height: 8),
                if (pet.stage != PetStage.adult) ...[
                  LinearProgressIndicator(
                    value: pet.exp / pet.stage.expToNext,
                    backgroundColor: AppColors.lightSage,
                    valueColor:
                        const AlwaysStoppedAnimation(AppColors.gold),
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${pet.exp} / ${pet.stage.expToNext} EXP',
                    style: AppTextStyles.caption,
                  ),
                ] else
                  Text(
                    'Fully grown!',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.gold,
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

class _EggCard extends ConsumerWidget {
  final Pet egg;
  const _EggCard({required this.egg});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.eggShell,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: AppColors.gold.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: Image.asset(
              'assets/pets/egg.png',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mystery Egg', style: AppTextStyles.headlineSmall),
                Text(
                  'Tap to hatch your new friend!',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _hatch(context, ref),
            icon: const Icon(Icons.egg_alt_outlined, color: AppColors.gold),
            iconSize: 28,
            tooltip: 'Hatch egg',
          ),
        ],
      ),
    );
  }

  Future<void> _hatch(BuildContext context, WidgetRef ref) async {
    final seniorId = await ref.read(seniorIdProvider.future);
    if (seniorId == null) return;
    await ref.read(petServiceProvider).hatchEgg(seniorId, egg.id);
  }
}

class _EmptyPetsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            const Icon(Icons.egg_outlined, size: 52, color: AppColors.lightSage),
            const SizedBox(height: 12),
            Text('No pets yet', style: AppTextStyles.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Complete your daily exercise goal consistently\nto earn your first egg!',
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
