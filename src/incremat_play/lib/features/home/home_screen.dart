import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../models/pet.dart';
import '../../models/senior.dart';
import '../../providers/auth_provider.dart';
import '../../providers/senior_provider.dart';
import '../../services/game_service.dart';
import '../celebration/egg_award_screen.dart';
import '../duet/duet_screen.dart';
import '../evolution/evolution_screen.dart';
import '../hatching/hatching_screen.dart';
import '../history/history_screen.dart';
import '../profile/profile_screen.dart';
import '../sanctuary/sanctuary_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _tab = 0;

  // Celebration tracking — populated from the first stream emission so that
  // existing eggs/pets don't trigger notices on launch.
  bool _celebInit = false;
  Set<String> _knownEggIds = {};
  Map<String, int> _knownStages = {};
  final List<Widget> _celebQueue = [];
  bool _showingCeleb = false;

  // Session tracking — seeds on first load so existing sessions are never
  // re-processed. New sessions trigger GameService to award EXP and eggs.
  bool _sessionsInit = false;
  Set<String> _knownSessionIds = {};
  bool _catchUpDone = false;

  final _screens = const [
    _PlayTab(),
    SanctuaryScreen(),
    HistoryScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Run after the first frame so providers are ready.
    WidgetsBinding.instance.addPostFrameCallback((_) => _catchUpSessions());
  }

  /// Processes every session that arrived while the app was closed.
  /// Reads the persisted high-water mark, fetches sessions after it,
  /// runs each through GameService in order, then updates the mark.
  Future<void> _catchUpSessions() async {
    if (_catchUpDone || !mounted) return;
    _catchUpDone = true;

    final seniorId = await ref.read(seniorIdProvider.future);
    if (seniorId == null || !mounted) return;

    final senior = ref.read(seniorProvider).valueOrNull;
    if (senior == null) return;

    final svc = ref.read(seniorServiceProvider);
    final since = await svc.getLastGameProcessedAt(seniorId);
    final sessions = await svc.getSessionsSince(seniorId, since);
    if (sessions.isEmpty || !mounted) return;

    // Process in chronological order so weekly logic is evaluated correctly.
    sessions.sort((a, b) => a.date.compareTo(b.date));

    DateTime? latestProcessed;
    for (final session in sessions) {
      try {
        await GameService().onSessionLogged(
          seniorId: seniorId,
          senior: senior,
          sessionDate: session.date,
        );
        latestProcessed = session.date;
      } catch (_) {
        // Swallow per-session errors; next launch will retry from last mark.
        break;
      }
    }

    if (latestProcessed != null) {
      await svc.markGameProcessed(seniorId, latestProcessed);
    }
  }

  void _onPetsChanged(List<Pet> pets) {
    final eggIds = pets.where((p) => !p.isHatched).map((p) => p.id).toSet();
    final stages = {
      for (final p in pets.where((p) => p.isHatched)) p.id: p.stage.index,
    };

    // First emission — seed state, don't celebrate pre-existing content.
    if (!_celebInit) {
      _celebInit = true;
      _knownEggIds = eggIds;
      _knownStages = stages;
      return;
    }

    // Detect a newly-awarded egg.
    final newEggs = eggIds.difference(_knownEggIds);

    // Detect an evolution (an already-hatched pet whose stage increased).
    Pet? evolved;
    PetStage? prevStage;
    for (final p in pets.where((p) => p.isHatched)) {
      final old = _knownStages[p.id];
      if (old != null && p.stage.index > old) {
        evolved = p;
        prevStage = PetStage.values[old];
        break;
      }
    }

    _knownEggIds = eggIds;
    _knownStages = stages;

    if (evolved != null && prevStage != null) {
      _enqueueCeleb(
          EvolutionScreen(pet: evolved, previousStage: prevStage));
    }
    if (newEggs.isNotEmpty) {
      _enqueueCeleb(const EggAwardScreen());
    }
  }

  void _enqueueCeleb(Widget screen) {
    _celebQueue.add(screen);
    _pumpCeleb();
  }

  Future<void> _pumpCeleb() async {
    if (_showingCeleb || _celebQueue.isEmpty || !mounted) return;
    _showingCeleb = true;
    final screen = _celebQueue.removeAt(0);
    await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(builder: (_) => screen, fullscreenDialog: true),
    );
    _showingCeleb = false;
    if (mounted) _pumpCeleb();
  }

  void _onSessionsChanged(List<ExerciseSession> sessions) {
    final ids = sessions.map((s) => s.id).toSet();

    // First emission — seed known IDs so we never re-process old sessions.
    if (!_sessionsInit) {
      _sessionsInit = true;
      _knownSessionIds = ids;
      return;
    }

    final newSessions =
        sessions.where((s) => !_knownSessionIds.contains(s.id)).toList();
    _knownSessionIds = ids;
    if (newSessions.isEmpty) return;

    final senior = ref.read(seniorProvider).valueOrNull;
    if (senior == null) return;

    for (final session in newSessions) {
      GameService().onSessionLogged(
        seniorId: senior.id,
        senior: senior,
        sessionDate: session.date,
      ).ignore(); // fire-and-forget; Firestore errors are caught inside
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    // Seed celebration state from any already-loaded pets so the first data
    // load never fires a notice for pre-existing eggs/pets.
    if (!_celebInit) {
      final current = ref.read(petsProvider).valueOrNull;
      if (current != null) _onPetsChanged(current);
    }
    // Listen to the live pet stream and fire full-screen celebrations.
    ref.listen<AsyncValue<List<Pet>>>(petsProvider, (_, next) {
      final pets = next.valueOrNull;
      if (pets != null) _onPetsChanged(pets);
    });

    // Seed session tracking, then listen for new sessions to process game logic.
    if (!_sessionsInit) {
      final current = ref.read(sessionsProvider).valueOrNull;
      if (current != null) _onSessionsChanged(current);
    }
    ref.listen<AsyncValue<List<ExerciseSession>>>(sessionsProvider, (_, next) {
      final sessions = next.valueOrNull;
      if (sessions != null) _onSessionsChanged(sessions);
    });
    return Scaffold(
      body: IndexedStack(index: _tab, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        backgroundColor: scheme.surface,
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
    final sessionsAsync = ref.watch(sessionsProvider);
    final activePet = ref.watch(activePetProvider);

    final senior = seniorAsync.valueOrNull;
    final sessions = sessionsAsync.valueOrNull ?? [];

    // Live reps from the mat (published by the caregiver app in real time).
    final live = ref.watch(liveSessionProvider).valueOrNull;
    final liveReps = (live?.isLive ?? false) ? live!.repCount : 0;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/images/home_background.png',
          fit: BoxFit.cover,
          alignment: Alignment.bottomCenter,
        ),
        // Dark overlay so text stays readable in dark mode
        if (isDark)
          Container(color: Colors.black.withValues(alpha: 0.52)),
        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 28),
                // Greeting — FittedBox prevents overflow at large text scale
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: senior != null
                      ? RichText(
                          text: TextSpan(
                            style: AppTextStyles.displayLarge.copyWith(
                              color: scheme.onSurface,
                            ),
                            children: [
                              const TextSpan(text: 'Hello, '),
                              TextSpan(
                                text: senior.name,
                                style: TextStyle(color: AppColors.sageGreen),
                              ),
                              const TextSpan(text: '!'),
                            ],
                          ),
                        )
                      : Text('Hello!', style: AppTextStyles.displayLarge),
                ),
                const SizedBox(height: 10),
                // Date — pill with backdrop for legibility over the image
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: scheme.surface.withValues(alpha: 0.82),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: AppColors.sageGreen.withValues(alpha: 0.35)),
                  ),
                  child: Text(
                    DateFormat('EEEE, MMMM d').format(DateTime.now()),
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.sageGreen,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Weekly progress + today's goal combined card
                if (senior != null)
                  _WeeklyProgressPath(
                      senior: senior,
                      sessions: sessions,
                      liveReps: liveReps),
                const SizedBox(height: 12),
                // Live Duet entry — exercise together with a friend.
                _DuetButton(),
                const SizedBox(height: 24),
                // Pet / egg — large, sits directly on the tatami mat
                petsAsync.when(
                  data: (pets) {
                    final eggs =
                        pets.where((p) => !p.isHatched).toList();
                    if (activePet == null && eggs.isEmpty) {
                      return _EmptyPetsCard();
                    }
                    String? numberLabel;
                    if (activePet != null) {
                      final ord = speciesOrdinal(
                          activePet, ref.read(hatchedPetsProvider));
                      if (ord.count > 1) numberLabel = '#${ord.index}';
                    }
                    return _PetDisplay(
                        activePet: activePet,
                        eggs: eggs,
                        numberLabel: numberLabel);
                  },
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(
                          color: AppColors.sageGreen),
                    ),
                  ),
                  error: (_, _) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 44),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Live Duet entry button ───────────────────────────────────────────────────

class _DuetButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const DuetScreen()),
        ),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: scheme.surface.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
                color: AppColors.sageGreen.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.sageGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.group_rounded,
                    color: AppColors.sageGreen, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Exercise Together',
                        style: AppTextStyles.labelLarge,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    Text('Pair up & count reps live',
                        style: AppTextStyles.caption.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.55)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  color: scheme.onSurface.withValues(alpha: 0.4)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Weekly progress + today's goal ───────────────────────────────────────────

class _WeeklyProgressPath extends StatelessWidget {
  final Senior senior;
  final List<ExerciseSession> sessions;
  final int liveReps;

  const _WeeklyProgressPath(
      {required this.senior, required this.sessions, this.liveReps = 0});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final today = DateTime.now();
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final days = List.generate(7, (i) => weekStart.add(Duration(days: i)));
    const dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    bool isSameDay(DateTime a, DateTime b) =>
        a.year == b.year && a.month == b.month && a.day == b.day;

    int completedDays = 0;
    final dayGoals = List.generate(7, (i) {
      final day = days[i];
      var reps = sessions
          .where((s) => isSameDay(s.date, day))
          .fold(0, (sum, s) => sum + s.repCount);
      // Today's circle reflects live reps in progress too.
      if (isSameDay(day, today)) reps += liveReps;
      final met = reps >= senior.dailyRepGoal;
      if (met) completedDays++;
      return met;
    });

    final completedTodayReps = sessions
        .where((s) => isSameDay(s.date, today))
        .fold(0, (sum, s) => sum + s.repCount);
    // Live reps belong to the current in-progress session, on top of any
    // already-completed sessions today.
    final todayReps = completedTodayReps + liveReps;
    final todayProgress =
        (todayReps / senior.dailyRepGoal).clamp(0.0, 1.0);
    final goalComplete = todayProgress >= 1.0;

    // ── Consecutive-day streak ──────────────────────────────────────────────
    // Count back from today (or yesterday, if today isn't done yet so the
    // streak isn't shown as broken mid-day) over days the goal was met.
    String keyOf(DateTime d) => '${d.year}-${d.month}-${d.day}';
    final repsByDay = <String, int>{};
    for (final s in sessions) {
      repsByDay[keyOf(s.date)] =
          (repsByDay[keyOf(s.date)] ?? 0) + s.repCount;
    }
    repsByDay[keyOf(today)] = (repsByDay[keyOf(today)] ?? 0) + liveReps;
    bool metOn(DateTime d) =>
        (repsByDay[keyOf(d)] ?? 0) >= senior.dailyRepGoal;
    var streak = 0;
    var cursor = metOn(today)
        ? today
        : today.subtract(const Duration(days: 1));
    while (metOn(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    final summaryText = completedDays == 7
        ? 'All 7 goals met this week — amazing!'
        : '$completedDays of 7 goals met this week';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.surface,
            AppColors.sageGreen.withValues(alpha: 0.10),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.sageGreen.withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Weekly Progress Path',
                    style: AppTextStyles.headlineSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
              if (streak >= 1) ...[
                const SizedBox(width: 8),
                _StreakChip(days: streak),
              ],
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(7, (i) {
              final day = days[i];
              final isToday = day.year == today.year &&
                  day.month == today.month &&
                  day.day == today.day;
              return _DayCircle(
                label: dayLabels[i],
                goalMet: dayGoals[i],
                isToday: isToday,
              );
            }),
          ),
          const SizedBox(height: 14),
          Text(
            summaryText,
            style: AppTextStyles.bodySmall.copyWith(
              color: completedDays >= 4
                  ? AppColors.sageGreen
                  : scheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
          Divider(
            height: 28,
            color: scheme.onSurface.withValues(alpha: 0.08),
          ),
          // Today's goal row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            goalComplete
                                ? "Today's Goal — Complete!"
                                : "Today's Goal",
                            style: AppTextStyles.caption.copyWith(
                              color: goalComplete
                                  ? AppColors.sageGreen
                                  : scheme.onSurface.withValues(alpha: 0.55),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (liveReps > 0) ...[
                          const SizedBox(width: 8),
                          const _LiveBadge(),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: todayProgress,
                      backgroundColor:
                          scheme.onSurface.withValues(alpha: 0.12),
                      valueColor: const AlwaysStoppedAnimation(
                          AppColors.sageGreen),
                      minHeight: 10,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$todayReps',
                    style: AppTextStyles.headlineLarge.copyWith(
                      color: goalComplete ? AppColors.sageGreen : null,
                    ),
                  ),
                  Text(
                    '/ ${senior.dailyRepGoal} reps',
                    style: AppTextStyles.caption.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
        ),
      ),
    );
  }
}

// Flame pill showing the current consecutive-day goal streak.
class _StreakChip extends StatelessWidget {
  final int days;
  const _StreakChip({required this.days});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.gold.withValues(alpha: 0.22),
            const Color(0xFFE8A030).withValues(alpha: 0.18),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_fire_department_rounded,
              size: 18, color: Color(0xFFE8761A)),
          const SizedBox(width: 4),
          Text(
            '$days day${days == 1 ? '' : 's'}',
            style: AppTextStyles.caption.copyWith(
              color: const Color(0xFFC75B12),
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

// Pulsing "LIVE" pill shown while a session is in progress on the mat.
class _LiveBadge extends StatefulWidget {
  const _LiveBadge();

  @override
  State<_LiveBadge> createState() => _LiveBadgeState();
}

class _LiveBadgeState extends State<_LiveBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.terracotta.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FadeTransition(
            opacity: Tween(begin: 0.35, end: 1.0).animate(_c),
            child: Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: AppColors.terracotta,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 5),
          Text(
            'LIVE',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.terracotta,
              fontWeight: FontWeight.w800,
              fontSize: 13,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _DayCircle extends StatelessWidget {
  final String label;
  final bool goalMet;
  final bool isToday;

  const _DayCircle({
    required this.label,
    required this.goalMet,
    required this.isToday,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Column(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: goalMet
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.sageGreen, AppColors.forest],
                  )
                : null,
            color: goalMet ? null : Colors.transparent,
            border: Border.all(
              color: isToday && !goalMet
                  ? AppColors.gold
                  : goalMet
                      ? Colors.transparent
                      : onSurface.withValues(alpha: 0.22),
              width: isToday ? 2.5 : 1.5,
            ),
            boxShadow: goalMet
                ? [
                    BoxShadow(
                      color: AppColors.sageGreen.withValues(alpha: 0.45),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : isToday
                    ? [
                        BoxShadow(
                          color: AppColors.gold.withValues(alpha: 0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
          ),
          child: goalMet
              ? const Icon(Icons.check_rounded, size: 20, color: Colors.white)
              : null,
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: isToday
                ? AppColors.gold
                : onSurface.withValues(alpha: 0.5),
            fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

// ── Pet display — sits directly on the tatami background ─────────────────────

class _PetDisplay extends StatelessWidget {
  final Pet? activePet;
  final List<Pet> eggs;
  // "#N" shown when you own more than one of the same species; otherwise null.
  final String? numberLabel;

  const _PetDisplay(
      {required this.activePet, required this.eggs, this.numberLabel});

  @override
  Widget build(BuildContext context) {
    Widget petWidget;
    String displayName;
    Widget? badge;

    if (activePet != null) {
      final pet = activePet!;
      petWidget = pet.species != null
          ? Image.asset(
              pet.species!.imagePath(pet.stage),
              width: 260,
              height: 260,
              fit: BoxFit.contain,
            )
          : const Icon(Icons.pets, size: 160, color: AppColors.sageGreen);
      displayName = pet.species?.stageName(pet.stage) ?? 'Companion';
      badge = pet.stage != PetStage.adult
          ? _ExpBadge('${pet.exp} / ${pet.stage.expToNext} EXP')
          : _ExpBadge('Fully Grown!');
    } else {
      petWidget = const _AnimatedEgg(size: 220);
      displayName = 'Mystery Egg';
      badge = null;
    }

    return Column(
      children: [
        Center(child: petWidget),
        const SizedBox(height: 10),
        Text(
          displayName,
          style: AppTextStyles.headlineLarge,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (activePet?.species != null) ...[
          const SizedBox(height: 3),
          Text(
            numberLabel != null
                ? '${activePet!.species!.label}  ·  $numberLabel'
                : activePet!.species!.label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.sageGreen,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
        ],
        if (badge != null) ...[
          const SizedBox(height: 8),
          badge,
        ],
        if (eggs.isNotEmpty) ...[
          const SizedBox(height: 20),
          if (activePet != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.egg_outlined,
                      size: 18, color: AppColors.gold),
                  const SizedBox(width: 6),
                  Text(
                    'You have an egg ready to hatch!',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.gold),
                  ),
                ],
              ),
            ),
          _HatchButton(egg: eggs.first),
        ],
      ],
    );
  }
}

class _ExpBadge extends StatelessWidget {
  final String text;
  const _ExpBadge(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.gold.withValues(alpha: 0.22),
            AppColors.gold.withValues(alpha: 0.10),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.55), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: AppColors.gold, size: 18),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.gold,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _HatchButton extends ConsumerWidget {
  final Pet egg;
  const _HatchButton({required this.egg});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 58,
      constraints: const BoxConstraints(minWidth: 220),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE8A030), AppColors.gold],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withValues(alpha: 0.45),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _hatch(context, ref),
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.egg_alt_outlined, color: Colors.white, size: 24),
                const SizedBox(width: 10),
                Text('Hatch Now!', style: AppTextStyles.buttonText),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _hatch(BuildContext context, WidgetRef ref) async {
    final seniorId = await ref.read(seniorIdProvider.future);
    if (seniorId == null || !context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HatchingScreen(egg: egg, seniorId: seniorId),
      ),
    );
  }
}

class _EmptyPetsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Icon(Icons.egg_outlined,
              size: 60,
              color: scheme.onSurface.withValues(alpha: 0.2)),
          const SizedBox(height: 14),
          Text('No companions yet',
              style: AppTextStyles.headlineSmall),
          const SizedBox(height: 10),
          Text(
            'Complete your daily exercise goal\nconsistently to earn your first egg!',
            style: AppTextStyles.bodyMedium.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.55)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Animated egg spritesheet ──────────────────────────────────────────────────

class _AnimatedEgg extends StatefulWidget {
  final double size;
  const _AnimatedEgg({this.size = 64});

  @override
  State<_AnimatedEgg> createState() => _AnimatedEggState();
}

class _AnimatedEggState extends State<_AnimatedEgg> {
  int _frame = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 400), (_) {
      if (mounted) setState(() => _frame = (_frame + 1) % 4);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final col = _frame % 2;
    final row = _frame ~/ 2;
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: ClipRect(
        child: OverflowBox(
          maxWidth: widget.size * 2,
          maxHeight: widget.size * 2,
          alignment: Alignment(
              col == 0 ? -1.0 : 1.0, row == 0 ? -1.0 : 1.0),
          child: Image.asset(
            'assets/pets/egg.png',
            width: widget.size * 2,
            height: widget.size * 2,
            fit: BoxFit.fill,
          ),
        ),
      ),
    );
  }
}
