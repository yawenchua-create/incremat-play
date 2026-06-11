import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../l10n/app_localizations.dart';
import '../../models/duet_session.dart';
import '../../providers/auth_provider.dart';
import '../../providers/mat_provider.dart';
import '../../providers/senior_provider.dart';

/// Live Duet — two people exercise at the same time and their live rep counts
/// add up into one shared meter, in real time. Pairing uses a throwaway "duet
/// code" (not a login credential), so it's safe to share and works remotely.
class DuetScreen extends ConsumerStatefulWidget {
  const DuetScreen({super.key});

  @override
  ConsumerState<DuetScreen> createState() => _DuetScreenState();
}

class _DuetScreenState extends ConsumerState<DuetScreen> {
  final _joinCtrl = TextEditingController();
  bool _busy = false;
  String? _error;
  DuetMode _mode = DuetMode.coop;

  @override
  void dispose() {
    _joinCtrl.dispose();
    super.dispose();
  }

  ({String id, String name, int goal})? _me() {
    final me = ref.read(seniorProvider).valueOrNull;
    final id = ref.read(seniorIdProvider).valueOrNull;
    if (me == null || id == null) return null;
    return (id: id, name: me.name, goal: me.dailyRepGoal);
  }

  Future<void> _create() async {
    final me = _me();
    if (me == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final code = await ref.read(seniorServiceProvider).createDuet(
          seniorId: me.id, name: me.name, goal: me.goal, mode: _mode);
      await ref.read(duetCodeProvider.notifier).setCode(code);
    } catch (_) {
      if (mounted) {
        setState(() => _error = AppLocalizations.of(context).couldNotCreateDuet);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _join() async {
    final code = _joinCtrl.text.trim();
    if (code.isEmpty) return;
    final me = _me();
    if (me == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final err = await ref.read(seniorServiceProvider).joinDuet(
          code: code, seniorId: me.id, name: me.name, goal: me.goal);
      if (!mounted) return;
      if (err != null) {
        setState(() => _error = err);
      } else {
        await ref.read(duetCodeProvider.notifier).setCode(code.toUpperCase());
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = AppLocalizations.of(context).couldNotJoinDuet);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _leave(DuetSession? session) async {
    final code = ref.read(duetCodeProvider);
    final myId = ref.read(seniorIdProvider).valueOrNull;
    if (code != null && session != null) {
      await ref
          .read(seniorServiceProvider)
          .leaveDuet(code, asHost: session.hostId == myId);
    }
    await ref.read(duetCodeProvider.notifier).setCode(null);
  }

  @override
  Widget build(BuildContext context) {
    final code = ref.watch(duetCodeProvider);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).exerciseTogether,
            style: AppTextStyles.headlineSmall),
      ),
      body: SafeArea(
        child: code == null ? _buildLobby() : _buildSession(code),
      ),
    );
  }

  // ── Lobby: create or join ───────────────────────────────────────────────────

  Widget _buildLobby() {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.sageGreen.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.group_rounded,
                  size: 52, color: AppColors.sageGreen),
            ),
          ),
          const SizedBox(height: 24),
          Text(l.workOutAsPair,
              style: AppTextStyles.headlineLarge, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(
            l.duetIntro,
            style: AppTextStyles.bodyMedium
                .copyWith(color: scheme.onSurface.withValues(alpha: 0.6)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          // Mode picker — team up (combined) or compete (head-to-head).
          Text(l.chooseMode,
              style: AppTextStyles.labelLarge
                  .copyWith(color: scheme.onSurface.withValues(alpha: 0.7))),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ModeCard(
                  icon: Icons.group_rounded,
                  title: l.modeCoop,
                  subtitle: l.modeCoopDesc,
                  selected: _mode == DuetMode.coop,
                  onTap: () => setState(() => _mode = DuetMode.coop),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ModeCard(
                  icon: Icons.emoji_events_rounded,
                  title: l.modeVersus,
                  subtitle: l.modeVersusDesc,
                  selected: _mode == DuetMode.versus,
                  onTap: () => setState(() => _mode = DuetMode.versus),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _busy ? null : _create,
              icon: _busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white))
                  : const Icon(Icons.add_rounded, color: Colors.white),
              label: Text(_mode == DuetMode.versus ? l.createMatch : l.createDuet,
                  style: AppTextStyles.buttonText),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                  child:
                      Divider(color: scheme.onSurface.withValues(alpha: 0.15))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(l.orJoinOne,
                    style: AppTextStyles.caption.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.5))),
              ),
              Expanded(
                  child:
                      Divider(color: scheme.onSurface.withValues(alpha: 0.15))),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _joinCtrl,
            textCapitalization: TextCapitalization.characters,
            style: AppTextStyles.headlineSmall.copyWith(letterSpacing: 4),
            textAlign: TextAlign.center,
            decoration: InputDecoration(hintText: l.enterDuetCode),
            onSubmitted: (_) => _join(),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            _errorBox(_error!),
          ],
          const SizedBox(height: 16),
          SizedBox(
            height: 52,
            child: OutlinedButton(
              onPressed: _busy ? null : _join,
              child: Text(l.joinDuet,
                  style: AppTextStyles.labelLarge
                      .copyWith(color: AppColors.sageGreen)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Active duet ──────────────────────────────────────────────────────────────

  Widget _buildSession(String code) {
    final l = AppLocalizations.of(context);
    final sessionAsync = ref.watch(duetSessionProvider(code));
    return sessionAsync.when(
      loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.sageGreen)),
      error: (_, _) => _endedView(l.couldntLoadDuet),
      data: (session) {
        if (session == null) {
          return _endedView(l.duetEnded);
        }
        final myId = ref.watch(seniorIdProvider).valueOrNull;
        final amHost = session.hostId == myId;
        final partnerId = amHost ? session.guestId : session.hostId;
        final partnerName = amHost ? session.guestName : session.hostName;
        final partnerGoal = amHost ? session.guestGoal : session.hostGoal;

        if (partnerId == null) {
          return _waitingView(code, session);
        }
        if (session.mode == DuetMode.versus) {
          return _versusView(
            session: session,
            partnerId: partnerId,
            partnerName: partnerName ?? l.partner,
            partnerGoal: partnerGoal ?? 25,
          );
        }
        return _liveView(
          session: session,
          partnerId: partnerId,
          partnerName: partnerName ?? l.partner,
          partnerGoal: partnerGoal ?? 25,
        );
      },
    );
  }

  Widget _waitingView(String code, DuetSession session) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      child: Column(
        children: [
          Text(l.shareCodeWithPartner,
              style: AppTextStyles.bodyMedium.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.6)),
              textAlign: TextAlign.center),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: code));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l.duetCodeCopied)),
              );
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
              decoration: BoxDecoration(
                color: AppColors.sageGreen.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: AppColors.sageGreen.withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(code,
                      style: AppTextStyles.statLarge.copyWith(
                          color: AppColors.forest, letterSpacing: 6)),
                  const SizedBox(width: 12),
                  const Icon(Icons.copy_rounded,
                      size: 22, color: AppColors.sageGreen),
                ],
              ),
            ),
          ),
          const SizedBox(height: 36),
          const CircularProgressIndicator(color: AppColors.sageGreen),
          const SizedBox(height: 16),
          Text(l.waitingForPartner,
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center),
          const SizedBox(height: 40),
          TextButton(
            onPressed: () => _leave(session),
            child: Text(l.cancel,
                style: AppTextStyles.labelLarge
                    .copyWith(color: AppColors.terracotta)),
          ),
        ],
      ),
    );
  }

  Widget _liveView({
    required DuetSession session,
    required String partnerId,
    required String partnerName,
    required int partnerGoal,
  }) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final me = ref.watch(seniorProvider).valueOrNull;
    final myName = me?.name ?? l.youWord;
    final myGoal = me?.dailyRepGoal ?? 25;

    // My reps come from the unified provider (instant BLE when the mat is
    // connected, Firebase otherwise); the partner is always remote.
    final myLive = ref.watch(myLiveProvider);
    final partnerLive = ref.watch(partnerLiveProvider(partnerId)).valueOrNull;
    final myReps = myLive.live ? myLive.reps : 0;
    final partnerReps =
        (partnerLive?.isLive ?? false) ? partnerLive!.repCount : 0;
    final total = myReps + partnerReps;
    final target = myGoal + partnerGoal;
    final progress = target > 0 ? (total / target).clamp(0.0, 1.0) : 0.0;
    final reached = target > 0 && total >= target;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.sageGreen.withValues(alpha: 0.18),
                  AppColors.gold.withValues(alpha: 0.12),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border:
                  Border.all(color: AppColors.sageGreen.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                Text(reached ? l.amazingTeamwork : l.repsTogether,
                    style: AppTextStyles.labelLarge.copyWith(
                        color: AppColors.sageGreen, letterSpacing: 0.5)),
                const SizedBox(height: 6),
                Text('$total',
                    style: AppTextStyles.statLarge
                        .copyWith(fontSize: 64, color: AppColors.forest)),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 12,
                    backgroundColor: scheme.onSurface.withValues(alpha: 0.12),
                    valueColor:
                        const AlwaysStoppedAnimation(AppColors.sageGreen),
                  ),
                ),
                const SizedBox(height: 6),
                Text(l.combinedGoal(total, target),
                    style: AppTextStyles.caption.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.6))),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _ParticipantCard(
            name: myName,
            reps: myReps,
            live: myLive.live,
            isYou: true,
          ),
          const SizedBox(height: 12),
          _ParticipantCard(
            name: partnerName,
            reps: partnerReps,
            live: partnerLive?.isLive ?? false,
            isYou: false,
          ),
          const SizedBox(height: 28),
          OutlinedButton.icon(
            onPressed: () => _leave(session),
            icon: const Icon(Icons.logout_rounded,
                size: 20, color: AppColors.terracotta),
            label: Text(l.endDuet,
                style: AppTextStyles.labelLarge
                    .copyWith(color: AppColors.terracotta)),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              side:
                  BorderSide(color: AppColors.terracotta.withValues(alpha: 0.4)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Competitive (versus) ─────────────────────────────────────────────────────

  Widget _versusView({
    required DuetSession session,
    required String partnerId,
    required String partnerName,
    required int partnerGoal,
  }) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final me = ref.watch(seniorProvider).valueOrNull;
    final myName = me?.name ?? l.youWord;
    final myGoal = (me?.dailyRepGoal ?? 25).clamp(1, 100000);

    final myLive = ref.watch(myLiveProvider);
    final partnerLive = ref.watch(partnerLiveProvider(partnerId)).valueOrNull;
    final myReps = myLive.live ? myLive.reps : 0;
    final partnerReps =
        (partnerLive?.isLive ?? false) ? partnerLive!.repCount : 0;

    final myProgress = (myReps / myGoal).clamp(0.0, 1.0);
    final partnerProgress = (partnerReps / partnerGoal).clamp(0.0, 1.0);
    final iFinished = myReps >= myGoal;
    final partnerFinished = partnerReps >= partnerGoal;

    // Banner: a winner once someone reaches their goal, otherwise who's ahead.
    final String banner;
    final Color bannerColor;
    if (iFinished || partnerFinished) {
      if (iFinished && partnerFinished) {
        banner = l.itsATie;
        bannerColor = AppColors.gold;
      } else if (iFinished) {
        banner = l.youWon;
        bannerColor = AppColors.sageGreen;
      } else {
        banner = l.partnerWon(partnerName);
        bannerColor = AppColors.terracotta;
      }
    } else if (myProgress > partnerProgress) {
      banner = l.youLead;
      bannerColor = AppColors.sageGreen;
    } else if (partnerProgress > myProgress) {
      banner = l.partnerLeads;
      bannerColor = AppColors.terracotta;
    } else {
      banner = l.neckAndNeck;
      bannerColor = AppColors.gold;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            decoration: BoxDecoration(
              color: bannerColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: bannerColor.withValues(alpha: 0.4)),
            ),
            child: Column(
              children: [
                Text(l.raceToGoal,
                    style: AppTextStyles.caption.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.6))),
                const SizedBox(height: 4),
                Text(banner,
                    style: AppTextStyles.headlineSmall
                        .copyWith(color: bannerColor),
                    textAlign: TextAlign.center),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _RacerCard(
            name: l.nameYou(myName),
            reps: myReps,
            goal: myGoal,
            progress: myProgress,
            live: myLive.live,
            finished: iFinished,
            color: AppColors.sageGreen,
            percentLabel: l.percentOfGoal((myProgress * 100).round()),
          ),
          const SizedBox(height: 12),
          _RacerCard(
            name: partnerName,
            reps: partnerReps,
            goal: partnerGoal,
            progress: partnerProgress,
            live: partnerLive?.isLive ?? false,
            finished: partnerFinished,
            color: AppColors.terracotta,
            percentLabel: l.percentOfGoal((partnerProgress * 100).round()),
          ),
          const SizedBox(height: 28),
          OutlinedButton.icon(
            onPressed: () => _leave(session),
            icon: const Icon(Icons.logout_rounded,
                size: 20, color: AppColors.terracotta),
            label: Text(l.endMatch,
                style: AppTextStyles.labelLarge
                    .copyWith(color: AppColors.terracotta)),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              side:
                  BorderSide(color: AppColors.terracotta.withValues(alpha: 0.4)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _endedView(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.group_off_rounded,
                size: 56, color: AppColors.subtleText),
            const SizedBox(height: 16),
            Text(message,
                style: AppTextStyles.bodyLarge, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () =>
                  ref.read(duetCodeProvider.notifier).setCode(null),
              child: Text(AppLocalizations.of(context).back, style: AppTextStyles.buttonText),
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorBox(String message) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.terracotta.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.terracotta, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.terracotta)),
          ),
        ],
      ),
    );
  }
}

class _ParticipantCard extends StatelessWidget {
  final String name;
  final int reps;
  final bool live;
  final bool isYou;

  const _ParticipantCard({
    required this.name,
    required this.reps,
    required this.live,
    required this.isYou,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: live
              ? AppColors.sageGreen.withValues(alpha: 0.4)
              : scheme.onSurface.withValues(alpha: 0.08),
          width: live ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.sageGreen.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: AppTextStyles.headlineSmall
                    .copyWith(color: AppColors.sageGreen),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isYou ? l.nameYou(name) : name,
                    style: AppTextStyles.labelLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: live
                            ? AppColors.sageGreen
                            : scheme.onSurface.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      live ? l.exercisingNow : l.waitingToStart,
                      style: AppTextStyles.caption.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.55)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(
            width: 56,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text('$reps',
                  style: AppTextStyles.statMedium
                      .copyWith(color: live ? AppColors.sageGreen : null)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Selectable card for picking coop vs versus mode in the lobby.
class _ModeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _ModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.sageGreen.withValues(alpha: 0.14)
                : scheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? AppColors.sageGreen
                  : scheme.onSurface.withValues(alpha: 0.12),
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon,
                  size: 34,
                  color: selected
                      ? AppColors.sageGreen
                      : scheme.onSurface.withValues(alpha: 0.5)),
              const SizedBox(height: 10),
              Text(title,
                  style: AppTextStyles.labelLarge.copyWith(
                      color: selected ? AppColors.forest : null),
                  textAlign: TextAlign.center),
              const SizedBox(height: 4),
              Text(subtitle,
                  style: AppTextStyles.caption.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.55)),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

/// A competitor's progress card in versus mode: name, live reps over their own
/// goal, a progress bar, and a trophy once they finish.
class _RacerCard extends StatelessWidget {
  final String name;
  final int reps;
  final int goal;
  final double progress;
  final bool live;
  final bool finished;
  final Color color;
  final String percentLabel;

  const _RacerCard({
    required this.name,
    required this.reps,
    required this.goal,
    required this.progress,
    required this.live,
    required this.finished,
    required this.color,
    required this.percentLabel,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: finished
              ? color
              : (live
                  ? color.withValues(alpha: 0.4)
                  : scheme.onSurface.withValues(alpha: 0.08)),
          width: finished ? 2 : (live ? 1.5 : 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(name,
                    style: AppTextStyles.labelLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
              if (finished)
                Icon(Icons.emoji_events_rounded, size: 22, color: color),
              const SizedBox(width: 8),
              Text('$reps',
                  style: AppTextStyles.statMedium.copyWith(color: color)),
              Text(' / $goal',
                  style: AppTextStyles.caption.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.5))),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: scheme.onSurface.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          const SizedBox(height: 6),
          Text(percentLabel,
              style: AppTextStyles.caption.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.55))),
        ],
      ),
    );
  }
}
