import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/text_size_provider.dart';

/// Service responsible for persisting and retrieving user preferences
/// such as Dark/Light theme mode and accessibility text scaling.
class PreferencesService {
  static const String keyThemeMode = 'app_theme_mode';
  static const String keyTextScale = 'app_text_scale';

  SharedPreferences? _prefs;

  PreferencesService([this._prefs]);

  /// Retrieve the saved ThemeMode, defaults to ThemeMode.light
  ThemeMode getThemeMode() {
    final value = _prefs?.getString(keyThemeMode);
    if (value == 'dark') return ThemeMode.dark;
    if (value == 'light') return ThemeMode.light;
    return ThemeMode.light;
  }

  /// Persist the selected ThemeMode to local storage
  Future<void> saveThemeMode(ThemeMode mode) async {
    final value = mode == ThemeMode.dark ? 'dark' : 'light';
    try {
      _prefs ??= await SharedPreferences.getInstance();
      await _prefs?.setString(keyThemeMode, value);
    } catch (_) {
      // Gracefully handled if SharedPreferences platform channel is unavailable in mock tests
    }
  }

  /// Retrieve the saved AppTextScale, defaults to AppTextScale.standard
  AppTextScale getTextScale() {
    final value = _prefs?.getString(keyTextScale);
    if (value == null) return AppTextScale.standard;
    for (final scale in AppTextScale.values) {
      if (scale.name == value) return scale;
    }
    return AppTextScale.standard;
  }

  /// Persist the selected AppTextScale to local storage
  Future<void> saveTextScale(AppTextScale scale) async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
      await _prefs?.setString(keyTextScale, scale.name);
    } catch (_) {
      // Gracefully handled if SharedPreferences platform channel is unavailable in mock tests
    }
  }
}

/// Riverpod provider for PreferencesService
final preferencesServiceProvider = Provider<PreferencesService>((ref) {
  return PreferencesService();
});

