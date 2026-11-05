import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/text_size_provider.dart';

enum HistoryViewMode { list, calendar }

/// Service responsible for persisting and retrieving user preferences
/// such as Dark/Light theme mode, accessibility text scaling, and history layout.
class PreferencesService {
  static const String keyThemeMode = 'app_theme_mode';
  static const String keyTextScale = 'app_text_scale';
  static const String keyHistoryViewMode = 'app_history_view_mode';
  static const String keyShowVoiceTranscript = 'app_history_show_voice_transcript';

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

  /// Retrieve the saved HistoryViewMode, defaults to HistoryViewMode.list
  HistoryViewMode getHistoryViewMode() {
    final value = _prefs?.getString(keyHistoryViewMode);
    if (value == 'calendar') return HistoryViewMode.calendar;
    return HistoryViewMode.list;
  }

  /// Persist the selected HistoryViewMode
  Future<void> saveHistoryViewMode(HistoryViewMode mode) async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
      await _prefs?.setString(keyHistoryViewMode, mode.name);
    } catch (_) {
      // Gracefully handled if SharedPreferences platform channel is unavailable in mock tests
    }
  }

  /// Retrieve the saved preference for displaying voice transcripts in history cards.
  /// Defaults to true (visible).
  bool getShowVoiceTranscript() {
    return _prefs?.getBool(keyShowVoiceTranscript) ?? true;
  }

  /// Persist the show voice transcript preference
  Future<void> saveShowVoiceTranscript(bool show) async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
      await _prefs?.setBool(keyShowVoiceTranscript, show);
    } catch (_) {
      // Gracefully handled if SharedPreferences platform channel is unavailable in mock tests
    }
  }
}

/// Riverpod provider for PreferencesService
final preferencesServiceProvider = Provider<PreferencesService>((ref) {
  return PreferencesService();
});

/// Riverpod provider for HistoryViewMode (List vs Calendar)
final historyViewModeProvider =
    NotifierProvider<HistoryViewModeNotifier, HistoryViewMode>(
        HistoryViewModeNotifier.new);

class HistoryViewModeNotifier extends Notifier<HistoryViewMode> {
  @override
  HistoryViewMode build() {
    return ref.watch(preferencesServiceProvider).getHistoryViewMode();
  }

  void setMode(HistoryViewMode mode) {
    state = mode;
    ref.read(preferencesServiceProvider).saveHistoryViewMode(mode);
  }

  void toggleMode() {
    final next = state == HistoryViewMode.list
        ? HistoryViewMode.calendar
        : HistoryViewMode.list;
    setMode(next);
  }
}

/// Riverpod provider for whether voice transcripts should be displayed in history cards
final showVoiceTranscriptProvider =
    NotifierProvider<ShowVoiceTranscriptNotifier, bool>(
        ShowVoiceTranscriptNotifier.new);

class ShowVoiceTranscriptNotifier extends Notifier<bool> {
  @override
  bool build() {
    return ref.watch(preferencesServiceProvider).getShowVoiceTranscript();
  }

  void toggle() {
    final next = !state;
    state = next;
    ref.read(preferencesServiceProvider).saveShowVoiceTranscript(next);
  }

  void setShow(bool show) {
    state = show;
    ref.read(preferencesServiceProvider).saveShowVoiceTranscript(show);
  }
}

