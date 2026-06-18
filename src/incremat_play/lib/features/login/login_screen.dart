import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/platform_tags.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/accessibility_provider.dart';
import '../../providers/auth_provider.dart';

/// The senior's sign-in screen. Far simpler than the caregiver login: the senior
/// enters (or NFC-taps) their join code — no email/password. Delegates to the
/// auth provider/AuthService which does the anonymous-auth + code lookup. Imports
/// nfc_manager directly so a card tap can fill in the code hands-free.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _ctrl = TextEditingController();
  bool _isLoading = false;
  bool _nfcScanning = false;
  bool _nfcAvailable = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    NfcManager.instance.isAvailable().then((v) {
      if (mounted) setState(() => _nfcAvailable = v);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    NfcManager.instance.stopSession().ignore();
    super.dispose();
  }

  Future<void> _scanNfc() async {
    final l = AppLocalizations.of(context);
    setState(() { _nfcScanning = true; _error = null; });
    await NfcManager.instance.startSession(
      onDiscovered: (tag) async {
        // Extract the card's hardware UID — works with any NFC card type.
        final uid = _extractUid(tag);
        await NfcManager.instance.stopSession();
        if (!mounted) return;
        if (uid == null) {
          setState(() {
            _nfcScanning = false;
            _error = l.couldNotReadCard;
          });
          return;
        }
        setState(() { _isLoading = true; _nfcScanning = false; _error = null; });
        try {
          final error = await ref.read(authServiceProvider).signInWithNfcUid(uid, l);
          if (!mounted) return;
          if (error == null) {
            // SharedPreferences now has the senior ID — tell the provider to re-read it.
            // Do NOT invalidate authStateProvider; that causes a brief null flash.
            ref.invalidate(seniorIdProvider);
          }
          setState(() { _isLoading = false; _error = error; });
        } catch (_) {
          if (!mounted) return;
          setState(() { _isLoading = false; _error = l.somethingWentWrong; });
        }
      },
    );
  }

  /// Extracts the UID from any NFC tag by trying each RF technology.
  String? _extractUid(NfcTag tag) {
    Uint8List? bytes;
    bytes ??= NfcA.from(tag)?.identifier;
    bytes ??= NfcB.from(tag)?.identifier;
    bytes ??= IsoDep.from(tag)?.identifier;
    bytes ??= NfcF.from(tag)?.identifier;
    bytes ??= NfcV.from(tag)?.identifier;
    if (bytes == null || bytes.isEmpty) return null;
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join('');
  }

  Future<void> _signIn() async {
    final code = _ctrl.text.trim();
    if (code.isEmpty) return;
    final l = AppLocalizations.of(context);
    setState(() { _isLoading = true; _error = null; });
    try {
      final error = await ref.read(authServiceProvider).signInWithJoinCode(code, l);
      if (!mounted) return;
      if (error == null) {
        // SharedPreferences now has the senior ID — tell the provider to re-read it.
        // Do NOT invalidate authStateProvider; that causes a brief null flash.
        ref.invalidate(seniorIdProvider);
      }
      setState(() { _isLoading = false; _error = error; });
    } catch (_) {
      if (!mounted) return;
      setState(() { _isLoading = false; _error = l.somethingWentWrong; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final highContrast =
        ref.watch(accessibilityProvider.select((s) => s.highContrast));
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final topInset = MediaQuery.of(context).padding.top;
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Gradient hero — sizes to its own content so the white text
            //    always sits on the green, at any text size. ──
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.forest, AppColors.sageGreen],
                ),
              ),
              padding: EdgeInsets.fromLTRB(28, topInset + 40, 28, 64),
              child: Column(
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.5),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.forest.withValues(alpha: 0.4),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.eco_rounded,
                        size: 52, color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'IncreMat Play',
                    style: AppTextStyles.displayLarge
                        .copyWith(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l.appTagline,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            // ── Form card — pulled up to overlap the gradient. The 36px gap it
            //    leaves at the bottom of the scroll view is the same colour as
            //    the scaffold, so it's invisible. ──
            Transform.translate(
              offset: const Offset(0, -36),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(36)),
                ),
                padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  Text(l.enterPlayCode,
                      style: AppTextStyles.headlineSmall),
                  const SizedBox(height: 6),
                  Text(
                    l.caregiverGivesCode,
                    style: AppTextStyles.bodySmall.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.6)),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _ctrl,
                    textCapitalization: TextCapitalization.characters,
                    style: AppTextStyles.headlineLarge.copyWith(letterSpacing: 4),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      hintText: 'ROSE-4821',
                      hintStyle: TextStyle(
                        color: scheme.onSurface.withValues(alpha: 0.4),
                        letterSpacing: 2,
                        fontSize: 20,
                      ),
                    ),
                    onSubmitted: (_) => _signIn(),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.terracotta.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              color: AppColors.terracotta, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(_error!,
                                style: AppTextStyles.bodySmall
                                    .copyWith(color: AppColors.terracotta)),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  // Gradient "Get Started" button
                  _GradientButton(
                    onPressed: _isLoading ? null : _signIn,
                    highContrast: highContrast,
                    child: _isLoading
                        ? SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.5, color: scheme.onPrimary),
                          )
                        : Text(l.getStarted,
                            style: AppTextStyles.buttonText
                                .copyWith(color: scheme.onPrimary)),
                  ),
                  if (_nfcAvailable) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                            child: Divider(
                                color: scheme.onSurface.withValues(alpha: 0.15))),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(l.or,
                              style: AppTextStyles.caption.copyWith(
                                  color:
                                      scheme.onSurface.withValues(alpha: 0.5))),
                        ),
                        Expanded(
                            child: Divider(
                                color: scheme.onSurface.withValues(alpha: 0.15))),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: OutlinedButton.icon(
                        onPressed:
                            (_isLoading || _nfcScanning) ? null : _scanNfc,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: scheme.primary,
                          side: BorderSide(
                              color: scheme.primary.withValues(alpha: 0.5)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28)),
                        ),
                        icon: _nfcScanning
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: scheme.primary),
                              )
                            : const Icon(Icons.nfc, size: 22),
                        label: Text(
                          _nfcScanning ? l.holdTagToPhone : l.tapNfcTag,
                          style: AppTextStyles.buttonText
                              .copyWith(color: scheme.primary),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 36),
                  Text(
                    l.askCaregiverForCode,
                    style: AppTextStyles.bodySmall.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.6)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  // In high-contrast mode the sage->forest gradient's light end drops below
  // AAA, so fall back to a solid AAA-grade accent fill instead.
  final bool highContrast;
  const _GradientButton({
    required this.onPressed,
    required this.child,
    this.highContrast = false,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    final accent = Theme.of(context).colorScheme.primary;
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        gradient: (!disabled && !highContrast)
            ? const LinearGradient(
                colors: [AppColors.sageGreen, AppColors.forest],
              )
            : null,
        color: disabled
            ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12)
            : (highContrast ? accent : null),
        borderRadius: BorderRadius.circular(28),
        boxShadow: !disabled
            ? [
                BoxShadow(
                  color: AppColors.sageGreen.withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(28),
          child: Center(child: child),
        ),
      ),
    );
  }
}
