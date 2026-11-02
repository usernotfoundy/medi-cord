import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:medi_cord/app.dart';
import 'package:medi_cord/core/services/preferences_service.dart';
import 'package:medi_cord/core/vitals/vital_type.dart';
import 'package:medi_cord/data/models/vital_reading.dart';
import 'package:medi_cord/features/history/calendar/calendar_day_tile.dart';
import 'package:medi_cord/features/history/calendar/day_vital_modal.dart';
import 'package:medi_cord/features/history/calendar/history_calendar_view.dart';
import 'package:medi_cord/features/record/record_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'widget_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('History Calendar View Tests', () {
    testWidgets('Can toggle between List View and Calendar View in History screen',
        (tester) async {
      final fakeRepo = FakeVitalRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            vitalRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: const MediCordApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to History tab
      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();

      // Verify View Switcher presence
      expect(find.text('List View'), findsOneWidget);
      expect(find.text('Calendar View'), findsOneWidget);

      // Tap Calendar View
      await tester.tap(find.text('Calendar View'));
      await tester.pumpAndSettle();

      // Verify Calendar View is now active
      expect(find.byType(HistoryCalendarView), findsOneWidget);

      // Switch back to List View
      await tester.tap(find.text('List View'));
      await tester.pumpAndSettle();

      expect(find.byType(HistoryCalendarView), findsNothing);
    });

    testWidgets('Calendar View renders month header, weekdays, and navigates months',
        (tester) async {
      final fakeRepo = FakeVitalRepository();
      final now = DateTime.now();
      final currentMonthStr = DateFormat('MMMM yyyy').format(now);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            vitalRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: const MediCordApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Go to History and switch to Calendar
      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Calendar View'));
      await tester.pumpAndSettle();

      // Verify current month in header
      expect(find.text(currentMonthStr), findsOneWidget);

      // Verify weekday abbreviations
      expect(find.text('Sun'), findsOneWidget);
      expect(find.text('Mon'), findsOneWidget);
      expect(find.text('Fri'), findsOneWidget);

      // Tap '<' (Previous Month)
      final prevBtn = find.byTooltip('Previous Month');
      expect(prevBtn, findsOneWidget);
      await tester.tap(prevBtn);
      await tester.pumpAndSettle();

      final prevMonth = DateTime(now.year, now.month - 1, 1);
      final prevMonthStr = DateFormat('MMMM yyyy').format(prevMonth);
      expect(find.text(prevMonthStr), findsOneWidget);

      // Tap 'Today' quick return badge
      final todayBtn = find.text('Today');
      expect(todayBtn, findsOneWidget);
      await tester.tap(todayBtn);
      await tester.pumpAndSettle();

      // Back to current month
      expect(find.text(currentMonthStr), findsOneWidget);
    });

    testWidgets('Tapping future date shows locked toast feedback',
        (tester) async {
      final fakeRepo = FakeVitalRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            vitalRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: const MediCordApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Go to History and switch to Calendar
      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Calendar View'));
      await tester.pumpAndSettle();

      // Navigate to next month so all days are in the future
      final nextBtn = find.byTooltip('Next Month');
      await tester.tap(nextBtn);
      await tester.pumpAndSettle();

      // Find a future day tile in the next month
      final dayTiles = find.byType(CalendarDayTile);
      expect(dayTiles, findsWidgets);

      // Tap a future day tile
      await tester.tap(dayTiles.at(15));
      await tester.pump(); // Start SnackBar animation

      // Verify locked toast message is shown
      expect(find.textContaining('is in the future and locked'), findsOneWidget);
    });

    testWidgets('Locked date toast adapts in dark mode with high contrast',
        (tester) async {
      final fakeRepo = FakeVitalRepository();
      final prefs = await SharedPreferences.getInstance();
      final service = PreferencesService(prefs);
      await service.saveThemeMode(ThemeMode.dark);

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

      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Calendar View'));
      await tester.pumpAndSettle();

      final nextBtn = find.byTooltip('Next Month');
      await tester.tap(nextBtn);
      await tester.pumpAndSettle();

      final dayTiles = find.byType(CalendarDayTile);
      await tester.tap(dayTiles.at(15));
      await tester.pump();

      // Find SnackBar and verify high contrast colors
      final snackBarFinder = find.byType(SnackBar);
      expect(snackBarFinder, findsOneWidget);
      final snackBar = tester.widget<SnackBar>(snackBarFinder);
      expect(snackBar.backgroundColor, const Color(0xFFF8FAFC));
    });

    testWidgets('Populated day displays top 2 vitals with colored bullets and opens modal on tap',
        (tester) async {
      final fakeRepo = FakeVitalRepository();
      final now = DateTime.now();
      final todayMorning = DateTime(now.year, now.month, now.day, 8, 30);
      final todayNoon = DateTime(now.year, now.month, now.day, 12, 15);
      final todayEvening = DateTime(now.year, now.month, now.day, 18, 45);

      // Add 3 readings for today: BP, Glucose, Heart Rate
      await fakeRepo.insertReading(VitalReading(
        type: VitalType.bloodPressure,
        valuePrimary: 120,
        valueSecondary: 80,
        unit: 'mmHg',
        rawTranscript: 'BP 120 over 80',
        recordedAt: todayMorning,
      ));
      await fakeRepo.insertReading(VitalReading(
        type: VitalType.glucose,
        valuePrimary: 110,
        unit: 'mg/dL',
        rawTranscript: 'glucose 110',
        recordedAt: todayNoon,
      ));
      await fakeRepo.insertReading(VitalReading(
        type: VitalType.heartRate,
        valuePrimary: 72,
        unit: 'bpm',
        rawTranscript: 'heart rate 72',
        recordedAt: todayEvening,
      ));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            vitalRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: const MediCordApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Go to History and switch to Calendar View
      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Calendar View'));
      await tester.pumpAndSettle();

      // Verify only the top 2 vitals are previewed on the date tile (rest in modal):
      // (Sorted DESC: heart rate at 18:45, glucose at 12:15)
      expect(find.text('HR 72'), findsOneWidget);
      expect(find.text('Glu 110'), findsOneWidget);

      // Tap on today's tile
      await tester.tap(find.text('HR 72'));
      await tester.pumpAndSettle();

      // Verify DayVitalModal opened
      expect(find.byType(DayVitalModal), findsOneWidget);
      expect(find.text('Vital Sign Logs'), findsOneWidget);
      expect(find.text('3 entries'), findsOneWidget);

      // Verify all 3 readings are displayed in modal
      expect(find.text('120 / 80 mmHg'), findsOneWidget);
      expect(find.text('110 mg/dL'), findsOneWidget);
      expect(find.text('72 bpm'), findsOneWidget);

      // Close modal
      final closeBtn = find.byTooltip('Close');
      await tester.tap(closeBtn);
      await tester.pumpAndSettle();

      expect(find.byType(DayVitalModal), findsNothing);
    });

    testWidgets('Locked and unlocked date tiles have identical uniform height',
        (tester) async {
      final fakeRepo = FakeVitalRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            vitalRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: const MediCordApp(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Calendar View'));
      await tester.pumpAndSettle();

      final firstTileSize =
          tester.getSize(find.byType(CalendarDayTile).first);
      final lastTileSize =
          tester.getSize(find.byType(CalendarDayTile).last);
      expect(firstTileSize.height, lastTileSize.height);
    });

    testWidgets('AnimatedSwitcher handles view transitions and modal smoothly',
        (tester) async {
      final fakeRepo = FakeVitalRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            vitalRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: const MediCordApp(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();

      // Tap Calendar View
      await tester.tap(find.text('Calendar View'));
      // Step halfway through 240ms animation
      await tester.pump(const Duration(milliseconds: 120));
      expect(find.byType(AnimatedSwitcher), findsWidgets);

      await tester.pumpAndSettle();
      expect(find.byType(HistoryCalendarView), findsOneWidget);
    });

    testWidgets('CalendarDayTile does not overflow horizontally or vertically at any scale',
        (tester) async {
      final readings = [
        VitalReading(
          id: 1,
          type: VitalType.bloodPressure,
          valuePrimary: 120,
          valueSecondary: 80,
          unit: 'mmHg',
          recordedAt: DateTime.now(),
          rawTranscript: 'BP 120 80',
        ),
        VitalReading(
          id: 2,
          type: VitalType.glucose,
          valuePrimary: 110,
          unit: 'mg/dL',
          recordedAt: DateTime.now(),
          rawTranscript: 'Glucose 110',
        ),
      ];

      for (final textScale in [1.0, 1.15, 1.3, 1.5]) {
        for (final tileWidth in [36.0, 42.0, 48.0, 60.0]) {
          for (final tileHeight in [70.0, 80.0, 92.0]) {
            await tester.pumpWidget(
              MaterialApp(
                home: MediaQuery(
                  data: MediaQueryData(
                    textScaler: TextScaler.linear(textScale),
                  ),
                  child: Scaffold(
                    body: Center(
                      child: SizedBox(
                        width: tileWidth,
                        height: tileHeight,
                        child: CalendarDayTile(
                          date: DateTime(2025, 9, 28),
                          isCurrentMonth: true,
                          isToday: true,
                          isFuture: false,
                          readings: readings,
                          onTap: () {},
                          onLockedTap: () {},
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
          }
        }
      }
    });

    testWidgets('BP in top 2 displays on date tile, and pulse is displayed in DayVitalModal',
        (tester) async {
      final fakeRepo = FakeVitalRepository();
      final now = DateTime.now();
      final todayMorning = DateTime(now.year, now.month, now.day, 8, 30);
      final todayAfternoon = DateTime(now.year, now.month, now.day, 14, 30);

      // Glucose in morning
      await fakeRepo.insertReading(VitalReading(
        type: VitalType.glucose,
        valuePrimary: 105,
        unit: 'mg/dL',
        rawTranscript: 'glucose 105',
        recordedAt: todayMorning,
      ));

      // BP with Pulse in afternoon (most recent)
      await fakeRepo.insertReading(VitalReading(
        type: VitalType.bloodPressure,
        valuePrimary: 120,
        valueSecondary: 80,
        valueTertiary: 72,
        unit: 'mmHg',
        rawTranscript: 'blood pressure 120 over 80 pulse 72',
        recordedAt: todayAfternoon,
      ));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            vitalRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: const MediCordApp(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Calendar View'));
      await tester.pumpAndSettle();

      // BP is top recent -> must display on date tile
      expect(find.text('BP 120/80 p72'), findsOneWidget);
      expect(find.text('Glu 105'), findsOneWidget);

      // Tap on the date tile to open DayVitalModal
      await tester.tap(find.text('BP 120/80 p72'));
      await tester.pumpAndSettle();

      // Verify DayVitalModal shows BP and pulse
      expect(find.byType(DayVitalModal), findsOneWidget);
      expect(find.textContaining('Pulse 72 bpm'), findsOneWidget);
      expect(find.text('Pulse: 72 bpm'), findsOneWidget);
    });
  });
}
