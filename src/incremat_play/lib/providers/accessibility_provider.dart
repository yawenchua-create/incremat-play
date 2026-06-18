import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds the senior's accessibility preferences — bigger text, light/dark mode,
/// and high-contrast — which feed the theme and MediaQuery so the whole app
/// adapts. Central to the senior-UX/SS618 requirement. Immutable state object
/// (copyWith) managed by a Notifier further down, persisted in SharedPreferences.
class AccessibilityState {
  final double textScale;      // multiplier on all font sizes (1.0 = normal)
  final ThemeMode themeMode;   // light / dark
  final bool highContrast;     // swaps in the high-contrast palette

  const AccessibilityState({
    this.textScale = 1.0,
    this.themeMode = ThemeMode.light,
    this.highContrast = false,
  });

  AccessibilityState copyWith({
    double? textScale,
    ThemeMode? themeMode,
    bool? highContrast,
  }) =>
      AccessibilityState(
        textScale: textScale ?? this.textScale,
        themeMode: themeMode ?? this.themeMode,
        highContrast: highContrast ?? this.highContrast,
      );
}

class AccessibilityNotifier extends Notifier<AccessibilityState> {
  static const _textScaleKey = 'text_scale';
  static const _themeModeKey = 'theme_mode';
  static const _highContrastKey = 'high_contrast';

  @override
  AccessibilityState build() {
    _load();
    return const AccessibilityState();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final scale = prefs.getDouble(_textScaleKey) ?? 1.0;
    final themeIndex = prefs.getInt(_themeModeKey) ?? 0;
    final highContrast = prefs.getBool(_highContrastKey) ?? false;
    state = AccessibilityState(
      textScale: scale,
      themeMode: ThemeMode.values[themeIndex],
      highContrast: highContrast,
    );
  }

  Future<void> setTextScale(double scale) async {
    state = state.copyWith(textScale: scale);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_textScaleKey, scale);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeModeKey, mode.index);
  }

  Future<void> setHighContrast(bool value) async {
    state = state.copyWith(highContrast: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_highContrastKey, value);
  }
}

final accessibilityProvider =
    NotifierProvider<AccessibilityNotifier, AccessibilityState>(
  AccessibilityNotifier.new,
);
