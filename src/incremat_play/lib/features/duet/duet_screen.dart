import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../l10n/app_localizations.dart';
import '../../models/duet_session.dart';
import '../../providers/auth_provider.dart';
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
          seniorId: me.id, name: me.name, goal: me.goal);
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
          const SizedBox(height: 32),
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
              label: Text(l.createDuet, style: AppTextStyles.buttonText),
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

    final myLive = ref.watch(liveSessionProvider).valueOrNull;
    final partnerLive = ref.watch(partnerLiveProvider(partnerId)).valueOrNull;
    final myReps = (myLive?.isLive ?? false) ? myLive!.repCount : 0;
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
            live: myLive?.isLive ?? false,
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
