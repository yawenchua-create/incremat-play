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
    final eventsAsync = ref.watch(expEventsProvider);

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Text('History',
                  style: AppTextStyles.displayMedium),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
              child: Text(
                'Your companions\' growth journey',
                style: AppTextStyles.bodyMedium.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.55)),
              ),
            ),
          ),
          eventsAsync.when(
            data: (events) {
              if (events.isEmpty) {
                return SliverToBoxAdapter(
                    child: _EmptyHistory());
              }
              return SliverPadding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => _ExpEventTile(
                      event: events[i],
                      isFirst: i == 0,
                      isLast: i == events.length - 1,
                    ),
                    childCount: events.length,
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
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

class _ExpEventTile extends StatelessWidget {
  final ExpEvent event;
  final bool isFirst;
  final bool isLast;

  const _ExpEventTile({
    required this.event,
    required this.isFirst,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dateLabel =
        DateFormat('EEEE, MMMM d').format(event.date).toUpperCase();
    final petSpecies = PetSpecies.values
        .where((s) => s.name == event.species)
        .firstOrNull;

    // Per-type accent colour, title, and subtitle.
    final Color accent;
    final String title;
    final String? subtitle;
    switch (event.type) {
      case HistoryEventType.eggReceived:
        accent = AppColors.gold;
        title = 'Received a Mystery Egg';
        subtitle = 'A new egg, ready to hatch!';
      case HistoryEventType.hatched:
        accent = AppColors.gold;
        final babyName =
            petSpecies?.stageName(PetStage.baby) ?? 'a new companion';
        title = 'Hatched into $babyName!';
        subtitle = petSpecies?.label;
      case HistoryEventType.exp:
        accent = AppColors.sageGreen;
        title = '+${event.amount} EXP — Daily Goal Met';
        subtitle = null;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline column
          SizedBox(
            width: 28,
            child: Column(
              children: [
                if (!isFirst)
                  Container(
                      width: 2,
                      height: 20,
                      color: scheme.onSurface.withValues(alpha: 0.18))
                else
                  const SizedBox(height: 20),
                Container(
                  width: 13,
                  height: 13,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent,
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.5),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Center(
                      child: Container(
                          width: 2,
                          color: scheme.onSurface.withValues(alpha: 0.18)),
                    ),
                  )
                else
                  const SizedBox(height: 20),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                top: 10,
                bottom: isLast ? 4 : 24,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Portrait
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _buildPortrait(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dateLabel,
                            style: AppTextStyles.caption.copyWith(
                              color: scheme.onSurface.withValues(alpha: 0.55),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            title,
                            style: AppTextStyles.bodyMedium
                                .copyWith(color: accent),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              style: AppTextStyles.caption.copyWith(
                                color:
                                    scheme.onSurface.withValues(alpha: 0.55),
                              ),
                            ),
                          ],
                          if (event.type == HistoryEventType.exp &&
                              event.evolved) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.gold.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'Evolved to '
                                '${petSpecies?.stageName(event.stageAfter) ?? event.stageAfter.label}!',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.gold,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPortrait() {
    if (event.type == HistoryEventType.eggReceived) {
      return const Icon(Icons.egg_rounded, size: 40, color: AppColors.gold);
    }
    if (event.species != null) {
      return Image.asset(
        _imagePath(event.species!, event.stageAfter),
        fit: BoxFit.contain,
      );
    }
    return const Icon(Icons.pets, size: 38, color: AppColors.sageGreen);
  }

  String _imagePath(String species, PetStage stage) {
    final stageName = stage == PetStage.egg ? 'baby' : stage.name;
    return 'assets/pets/${species}_$stageName.png';
  }
}

class _EmptyHistory extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            Icon(Icons.auto_awesome_outlined,
                size: 56,
                color: scheme.onSurface.withValues(alpha: 0.2)),
            const SizedBox(height: 16),
            Text('No EXP events yet',
                style: AppTextStyles.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'When your companion gains EXP,\nit will appear here.',
              style: AppTextStyles.bodySmall.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.6)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
