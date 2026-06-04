import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../l10n/app_localizations.dart';
import '../../models/pet.dart';
import '../../providers/accessibility_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/senior_provider.dart';
import '../../services/pet_service.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final seniorAsync = ref.watch(seniorProvider);
    final textScale = ref.watch(accessibilityProvider.select((s) => s.textScale));
    final themeMode = ref.watch(accessibilityProvider.select((s) => s.themeMode));
    final highContrast = ref.watch(accessibilityProvider.select((s) => s.highContrast));
    final notifier = ref.read(accessibilityProvider.notifier);
    final locale = ref.watch(localeProvider);

    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Text(l.profileTitle, style: AppTextStyles.displayMedium),
            const SizedBox(height: 4),
            Text(
              l.profileSubtitle,
              style: AppTextStyles.bodyMedium.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.55)),
            ),
            const SizedBox(height: 28),
            seniorAsync.when(
              data: (senior) => senior != null
                  ? _ProfileCard(name: senior.name)
                  : const SizedBox.shrink(),
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 24),
            _SettingCard(
              title: l.language,
              child: Row(
                children: [
                  Expanded(
                    child: _LangOption(
                      label: l.english,
                      selected: locale.languageCode == 'en',
                      onTap: () => ref
                          .read(localeProvider.notifier)
                          .setLocale(const Locale('en')),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _LangOption(
                      label: l.chinese,
                      selected: locale.languageCode == 'zh',
                      onTap: () => ref
                          .read(localeProvider.notifier)
                          .setLocale(const Locale('zh')),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(l.accessibility, style: AppTextStyles.headlineSmall),
            const SizedBox(height: 12),
            _SettingCard(
              title: l.textSize,
              child: Column(
                children: [
                  Slider(
                    value: textScale,
                    min: 0.9,
                    max: 1.6,
                    divisions: 7,
                    activeColor: AppColors.sageGreen,
                    onChanged: (v) => notifier.setTextScale(v),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('A',
                          style: AppTextStyles.bodySmall.copyWith(
                              color: scheme.onSurface.withValues(alpha: 0.6))),
                      Text(
                        'A',
                        style: AppTextStyles.bodyLarge.copyWith(fontSize: 24),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _SettingCard(
              title: l.appearance,
              child: Column(
                children: [
                  _ThemeOption(
                    label: l.themeLight,
                    icon: Icons.light_mode_outlined,
                    selected: themeMode == ThemeMode.light,
                    onTap: () => notifier.setThemeMode(ThemeMode.light),
                  ),
                  const SizedBox(height: 8),
                  _ThemeOption(
                    label: l.themeDark,
                    icon: Icons.dark_mode_outlined,
                    selected: themeMode == ThemeMode.dark,
                    onTap: () => notifier.setThemeMode(ThemeMode.dark),
                  ),
                  const SizedBox(height: 8),
                  _ThemeOption(
                    label: l.themeSystem,
                    icon: Icons.phone_android_outlined,
                    selected: themeMode == ThemeMode.system,
                    onTap: () => notifier.setThemeMode(ThemeMode.system),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _SettingCard(
              title: l.highContrast,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(l.enableHighContrast, style: AppTextStyles.bodyMedium),
                  Switch(
                    value: highContrast,
                    onChanged: (v) => notifier.setHighContrast(v),
                    activeThumbColor: AppColors.sageGreen,
                    activeTrackColor:
                        AppColors.sageGreen.withValues(alpha: 0.4),
                  ),
                ],
              ),
            ),
            if (kDebugMode) ...[
              const SizedBox(height: 28),
              const _DebugPanel(),
            ],
            const SizedBox(height: 28),
            OutlinedButton.icon(
              onPressed: () => _confirmSignOut(context, ref),
              icon: const Icon(Icons.logout, size: 20),
              label: Text(l.signOut, style: AppTextStyles.labelLarge.copyWith(
                color: AppColors.terracotta,
              )),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.terracotta,
                side: BorderSide(
                    color: AppColors.terracotta.withValues(alpha: 0.4)),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.signOutQ, style: AppTextStyles.headlineSmall),
        content: Text(
          l.signOutBody,
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              l.signOut,
              style: TextStyle(color: AppColors.terracotta),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(authServiceProvider).signOut();
    }
  }
}

class _ProfileCard extends StatelessWidget {
  final String name;
  const _ProfileCard({required this.name});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: scheme.onSurface.withValues(alpha: 0.05),
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
              color: AppColors.sageGreen.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, size: 36, color: AppColors.sageGreen),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: AppTextStyles.headlineLarge),
              Text(AppLocalizations.of(context).exerciser,
                  style: AppTextStyles.bodySmall.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.55))),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SettingCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.labelLarge),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.sageGreen.withValues(alpha: 0.14)
              : Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.sageGreen : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 20,
                color: selected
                    ? AppColors.sageGreen
                    : Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.55)),
            const SizedBox(width: 12),
            Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: selected
                    ? AppColors.sageGreen
                    : Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const Spacer(),
            if (selected)
              const Icon(Icons.check, size: 18, color: AppColors.sageGreen),
          ],
        ),
      ),
    );
  }
}

class _LangOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LangOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.sageGreen.withValues(alpha: 0.14)
              : Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.sageGreen : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: selected
                  ? AppColors.sageGreen
                  : Theme.of(context).colorScheme.onSurface,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}

class _DebugPanel extends ConsumerStatefulWidget {
  const _DebugPanel();

  @override
  ConsumerState<_DebugPanel> createState() => _DebugPanelState();
}

class _DebugPanelState extends ConsumerState<_DebugPanel> {
  bool _busy = false;
  String? _lastMsg;
  final _petService = PetService();

  Future<void> _run(Future<void> Function(String seniorId) action) async {
    final seniorId = await ref.read(seniorIdProvider.future);
    if (seniorId == null) {
      setState(() { _lastMsg = 'No senior ID — are you logged in?'; });
      return;
    }
    setState(() { _busy = true; _lastMsg = null; });
    try {
      await action(seniorId);
      setState(() { _lastMsg = 'Done'; });
    } catch (e) {
      setState(() { _lastMsg = e.toString(); });
    } finally {
      setState(() { _busy = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.terracotta.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.terracotta.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bug_report_outlined,
                  size: 16, color: AppColors.terracotta),
              const SizedBox(width: 6),
              Text('Debug (test only)',
                  style: AppTextStyles.labelLarge
                      .copyWith(color: AppColors.terracotta)),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _DebugButton(
                label: 'Award Egg',
                busy: _busy,
                onTap: () => _run((id) => _petService.awardEgg(id)),
              ),
              _DebugButton(
                label: '+5 EXP',
                busy: _busy,
                onTap: () => _run((id) async {
                  // Target the pet currently shown on Home/Sanctuary, not just
                  // the most-recently-awarded one.
                  final pet = ref.read(activePetProvider);
                  if (pet == null) return;
                  final stageBefore = pet.stage;
                  await _petService.addExp(id, pet.id, 5);
                  final updated = await _petService.getPet(id, pet.id);
                  final evolved =
                      updated != null && updated.stage != stageBefore;
                  await FirebaseFirestore.instance
                      .collection('seniors')
                      .doc(id)
                      .collection('expEvents')
                      .add(ExpEvent(
                        id: '',
                        date: DateTime.now(),
                        petId: pet.id,
                        species: pet.species?.name,
                        stageBefore: stageBefore,
                        stageAfter: updated?.stage ?? stageBefore,
                        amount: 5,
                        evolved: evolved,
                      ).toMap());
                }),
              ),
              _DebugButton(
                label: 'Clear Egg Cooldown',
                busy: _busy,
                onTap: () => _run((id) async {
                  await FirebaseFirestore.instance
                      .collection('seniors')
                      .doc(id)
                      .update({'lastEggAwardedWeek': null});
                }),
              ),
            ],
          ),
          if (_lastMsg != null) ...[
            const SizedBox(height: 8),
            Text(_lastMsg!,
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.terracotta)),
          ],
        ],
      ),
    );
  }
}

class _DebugButton extends StatelessWidget {
  final String label;
  final bool busy;
  final VoidCallback onTap;
  const _DebugButton(
      {required this.label, required this.busy, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: busy ? null : onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.terracotta,
        side: BorderSide(color: AppColors.terracotta.withValues(alpha: 0.4)),
        minimumSize: Size.zero,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(label, style: AppTextStyles.caption),
    );
  }
}
