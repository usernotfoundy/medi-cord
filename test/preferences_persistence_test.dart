import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medi_cord/app.dart';
import 'package:medi_cord/core/services/preferences_service.dart';
import 'package:medi_cord/core/theme/text_size_provider.dart';
import 'package:medi_cord/core/theme/theme_provider.dart';
import 'package:medi_cord/features/record/record_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'widget_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('PreferencesService Unit Tests', () {
    test('Default values return Light theme and Standard text scale', () async {
      final prefs = await SharedPreferences.getInstance();
      final service = PreferencesService(prefs);

      expect(service.getThemeMode(), ThemeMode.light);
      expect(service.getTextScale(), AppTextScale.standard);
    });

    test('ThemeMode persistence stores and restores Dark mode', () async {
      final prefs = await SharedPreferences.getInstance();
      final service = PreferencesService(prefs);

      await service.saveThemeMode(ThemeMode.dark);
      expect(service.getThemeMode(), ThemeMode.dark);

      // Verify another service instance reading the same SharedPreferences
      final freshService = PreferencesService(prefs);
      expect(freshService.getThemeMode(), ThemeMode.dark);
    });

    test('AppTextScale persistence stores and restores custom scale', () async {
      final prefs = await SharedPreferences.getInstance();
      final service = PreferencesService(prefs);

      await service.saveTextScale(AppTextScale.extraLarge);
      expect(service.getTextScale(), AppTextScale.extraLarge);

      // Verify fresh instance
      final freshService = PreferencesService(prefs);
      expect(freshService.getTextScale(), AppTextScale.extraLarge);
    });

    test('ShowVoiceTranscript persistence stores and restores preference', () async {
      final prefs = await SharedPreferences.getInstance();
      final service = PreferencesService(prefs);

      expect(service.getShowVoiceTranscript(), isTrue);
      await service.saveShowVoiceTranscript(false);
      expect(service.getShowVoiceTranscript(), isFalse);

      final freshService = PreferencesService(prefs);
      expect(freshService.getShowVoiceTranscript(), isFalse);
    });
  });

  group('Riverpod Notifiers Persistence Integration', () {
    test('ThemeModeNotifier persists theme changes across ProviderContainers', () async {
      final prefs = await SharedPreferences.getInstance();
      final service = PreferencesService(prefs);

      // Session 1: Change to dark mode
      final container1 = ProviderContainer(
        overrides: [
          preferencesServiceProvider.overrideWithValue(service),
        ],
      );
      expect(container1.read(themeModeProvider), ThemeMode.light);

      container1.read(themeModeProvider.notifier).toggleTheme();
      expect(container1.read(themeModeProvider), ThemeMode.dark);

      // Session 2 (simulating app relaunch with fresh container):
      final container2 = ProviderContainer(
        overrides: [
          preferencesServiceProvider.overrideWithValue(service),
        ],
      );
      expect(container2.read(themeModeProvider), ThemeMode.dark);
    });

    test('TextScaleNotifier persists scale changes across ProviderContainers', () async {
      final prefs = await SharedPreferences.getInstance();
      final service = PreferencesService(prefs);

      // Session 1: Change to Huge scale
      final container1 = ProviderContainer(
        overrides: [
          preferencesServiceProvider.overrideWithValue(service),
        ],
      );
      expect(container1.read(textScaleProvider), AppTextScale.standard);

      container1.read(textScaleProvider.notifier).setScale(AppTextScale.huge);
      expect(container1.read(textScaleProvider), AppTextScale.huge);

      // Session 2 (simulating app relaunch with fresh container):
      final container2 = ProviderContainer(
        overrides: [
          preferencesServiceProvider.overrideWithValue(service),
        ],
      );
      expect(container2.read(textScaleProvider), AppTextScale.huge);
    });

    test('ShowVoiceTranscriptNotifier toggles and persists preference', () async {
      final prefs = await SharedPreferences.getInstance();
      final service = PreferencesService(prefs);

      final container1 = ProviderContainer(
        overrides: [
          preferencesServiceProvider.overrideWithValue(service),
        ],
      );
      expect(container1.read(showVoiceTranscriptProvider), isTrue);

      container1.read(showVoiceTranscriptProvider.notifier).toggle();
      expect(container1.read(showVoiceTranscriptProvider), isFalse);

      final container2 = ProviderContainer(
        overrides: [
          preferencesServiceProvider.overrideWithValue(service),
        ],
      );
      expect(container2.read(showVoiceTranscriptProvider), isFalse);
    });
  });

  group('UI Widget Persistence Tests', () {
    testWidgets('Toggling theme saves dark mode and preserves it on app restart', (tester) async {
      final fakeRepo = FakeVitalRepository();
      final prefs = await SharedPreferences.getInstance();
      final service = PreferencesService(prefs);

      // App Launch 1
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            vitalRepositoryProvider.overrideWithValue(fakeRepo),
            preferencesServiceProvider.overrideWithValue(service),
          ],
          child: const MediCordApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Starts in Light mode
      expect(find.text('Light'), findsOneWidget);

      // Switch to Dark mode
      await tester.tap(find.text('Light'));
      await tester.pumpAndSettle();
      expect(find.text('Dark'), findsOneWidget);

      // Simulate App Restart (Relaunch with fresh ProviderScope but shared prefs)
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            vitalRepositoryProvider.overrideWithValue(fakeRepo),
            preferencesServiceProvider.overrideWithValue(service),
          ],
          child: const MediCordApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Should immediately be in Dark mode on next start!
      expect(find.text('Dark'), findsOneWidget);
    });

    testWidgets('Selecting text size saves scale and preserves it on app restart', (tester) async {
      final fakeRepo = FakeVitalRepository();
      final prefs = await SharedPreferences.getInstance();
      final service = PreferencesService(prefs);

      // App Launch 1
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            vitalRepositoryProvider.overrideWithValue(fakeRepo),
            preferencesServiceProvider.overrideWithValue(service),
          ],
          child: const MediCordApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Open Text Size modal
      final textSizeBtn = find.byTooltip('Text Size (Standard)');
      expect(textSizeBtn, findsOneWidget);
      await tester.tap(textSizeBtn);
      await tester.pumpAndSettle();

      // Select 'Large'
      final largeOption = find.text('Large');
      expect(largeOption, findsOneWidget);
      await tester.tap(largeOption);
      await tester.pumpAndSettle();

      // Simulate App Restart (Relaunch with fresh ProviderScope but shared prefs)
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            vitalRepositoryProvider.overrideWithValue(fakeRepo),
            preferencesServiceProvider.overrideWithValue(service),
          ],
          child: const MediCordApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Tooltip should reflect Large on restart without user needing to change it again
      expect(find.byTooltip('Text Size (Large)'), findsOneWidget);
    });
  });
}

