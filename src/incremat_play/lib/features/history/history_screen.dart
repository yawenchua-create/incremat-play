import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../models/pet.dart';
import '../../providers/senior_provider.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(sessionsProvider);
    final seniorAsync = ref.watch(seniorProvider);

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Text('History', style: AppTextStyles.displayMedium),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
              child: Text(
                'Your recent exercise sessions',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.subtleText),
              ),
            ),
          ),
          seniorAsync.when(
            data: (senior) => sessionsAsync.when(
              data: (sessions) {
                if (sessions.isEmpty) {
                  return SliverToBoxAdapter(child: _EmptyHistory());
                }
                final goal = senior?.dailyRepGoal ?? 25;
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _SessionTile(
                            session: sessions[i], dailyGoal: goal),
                      ),
                      childCount: sessions.length,
                    ),
                  ),
                );
              },
              loading: () => const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(
                        color: AppColors.sageGreen),
                  ),
                ),
              ),
              error: (_, _) =>
                  const SliverToBoxAdapter(child: SizedBox.shrink()),
            ),
            loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
            error: (_, _) =>
                const SliverToBoxAdapter(child: SizedBox.shrink()),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  final ExerciseSession session;
  final int dailyGoal;

  const _SessionTile({required this.session, required this.dailyGoal});

  @override
  Widget build(BuildContext context) {
    final goalMet = session.repCount >= dailyGoal;
    final dateLabel = DateFormat('EEE, MMM d').format(session.date);
    final timeLabel = DateFormat('h:mm a').format(session.date);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.espresso.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: goalMet
                  ? AppColors.lightSage.withValues(alpha: 0.5)
                  : AppColors.warmCream,
              shape: BoxShape.circle,
            ),
            child: Icon(
              goalMet ? Icons.check_circle_outline : Icons.fitness_center,
              color: goalMet ? AppColors.sageGreen : AppColors.subtleText,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(dateLabel, style: AppTextStyles.labelLarge),
                Text(timeLabel, style: AppTextStyles.caption),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${session.repCount} reps',
                style: AppTextStyles.labelLarge,
              ),
              if (session.avgRepTimeSeconds > 0)
                Text(
                  '${session.avgRepTimeSeconds.toStringAsFixed(1)}s avg',
                  style: AppTextStyles.caption,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
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
            const Icon(Icons.bar_chart_outlined,
                size: 56, color: AppColors.lightSage),
            const SizedBox(height: 16),
            Text('No sessions yet', style: AppTextStyles.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Your exercise history will\nappear here after your first session.',
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
