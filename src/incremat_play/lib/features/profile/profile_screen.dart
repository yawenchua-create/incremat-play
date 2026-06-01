import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../providers/accessibility_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/senior_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seniorAsync = ref.watch(seniorProvider);
    final textScale = ref.watch(accessibilityProvider.select((s) => s.textScale));
    final themeMode = ref.watch(accessibilityProvider.select((s) => s.themeMode));
    final highContrast = ref.watch(accessibilityProvider.select((s) => s.highContrast));
    final notifier = ref.read(accessibilityProvider.notifier);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Text('Profile', style: AppTextStyles.displayMedium),
            const SizedBox(height: 4),
            Text(
              'Your settings & accessibility',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.subtleText),
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
            Text('Accessibility', style: AppTextStyles.headlineSmall),
            const SizedBox(height: 12),
            _SettingCard(
              title: 'Text Size',
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
                      Text('A', style: AppTextStyles.bodySmall),
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
              title: 'Appearance',
              child: Column(
                children: [
                  _ThemeOption(
                    label: 'Light',
                    icon: Icons.light_mode_outlined,
                    selected: themeMode == ThemeMode.light,
                    onTap: () => notifier.setThemeMode(ThemeMode.light),
                  ),
                  const SizedBox(height: 8),
                  _ThemeOption(
                    label: 'Dark',
                    icon: Icons.dark_mode_outlined,
                    selected: themeMode == ThemeMode.dark,
                    onTap: () => notifier.setThemeMode(ThemeMode.dark),
                  ),
                  const SizedBox(height: 8),
                  _ThemeOption(
                    label: 'System',
                    icon: Icons.phone_android_outlined,
                    selected: themeMode == ThemeMode.system,
                    onTap: () => notifier.setThemeMode(ThemeMode.system),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _SettingCard(
              title: 'High Contrast',
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Enable high contrast', style: AppTextStyles.bodyMedium),
                  Switch(
                    value: highContrast,
                    onChanged: (v) => notifier.setHighContrast(v),
                    activeThumbColor: AppColors.sageGreen,
                    activeTrackColor: AppColors.lightSage,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            OutlinedButton.icon(
              onPressed: () => _confirmSignOut(context, ref),
              icon: const Icon(Icons.logout, size: 20),
              label: Text('Sign Out', style: AppTextStyles.labelLarge.copyWith(
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Sign out?', style: AppTextStyles.headlineSmall),
        content: Text(
          'You can sign back in with your play code.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Sign Out',
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
            decoration: const BoxDecoration(
              color: AppColors.lightSage,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, size: 36, color: AppColors.sageGreen),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: AppTextStyles.headlineLarge),
              Text('Exerciser', style: AppTextStyles.bodySmall),
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
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
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
              ? AppColors.lightSage.withValues(alpha: 0.3)
              : AppColors.warmCream,
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
                color: selected ? AppColors.sageGreen : AppColors.subtleText),
            const SizedBox(width: 12),
            Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: selected ? AppColors.sageGreen : AppColors.espresso,
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
