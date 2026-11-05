import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medi_cord/core/services/preferences_service.dart';
import 'package:medi_cord/core/vitals/vital_type.dart';
import 'package:medi_cord/data/models/vital_reading.dart';
import 'package:medi_cord/features/history/history_filter_controller.dart';
import 'package:medi_cord/features/history/widgets/history_filter_bar.dart';
import 'package:medi_cord/features/history/widgets/history_filter_sheet.dart';
import 'package:medi_cord/features/record/record_controller.dart';

void main() {
  group('filterHistoryReadings unit tests', () {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day, 10, 30);
    final yesterday = today.subtract(const Duration(days: 1));
    final threeDaysAgo = today.subtract(const Duration(days: 3));
    final tenDaysAgo = today.subtract(const Duration(days: 10));
    final fortyDaysAgo = today.subtract(const Duration(days: 40));

    final sampleReadings = [
      VitalReading(
        id: 1,
        type: VitalType.bloodPressure,
        valuePrimary: 120,
        valueSecondary: 80,
        recordedAt: today,
      ),
      VitalReading(
        id: 2,
        type: VitalType.bloodGlucose,
        valuePrimary: 95,
        recordedAt: today,
      ),
      VitalReading(
        id: 3,
        type: VitalType.heartRate,
        valuePrimary: 72,
        recordedAt: yesterday,
      ),
      VitalReading(
        id: 4,
        type: VitalType.bloodPressure,
        valuePrimary: 130,
        valueSecondary: 85,
        recordedAt: threeDaysAgo,
      ),
      VitalReading(
        id: 5,
        type: VitalType.temperature,
        valuePrimary: 98.6,
        recordedAt: tenDaysAgo,
      ),
      VitalReading(
        id: 6,
        type: VitalType.weight,
        valuePrimary: 165,
        recordedAt: fortyDaysAgo,
      ),
    ];

    test('returns all readings when no filter is active', () {
      const state = HistoryFilterState();
      final result = filterHistoryReadings(sampleReadings, state);
      expect(result.length, 6);
    });

    test('filters by vital type correctly', () {
      final state = const HistoryFilterState().copyWith(
        selectedVital: () => VitalType.bloodPressure,
      );
      final result = filterHistoryReadings(sampleReadings, state);
      expect(result.length, 2);
      expect(result.every((r) => r.type == VitalType.bloodPressure), isTrue);
    });

    test('filters by Today date preset correctly', () {
      final state = const HistoryFilterState().copyWith(
        datePreset: HistoryDatePreset.today,
      );
      final result = filterHistoryReadings(sampleReadings, state);
      expect(result.length, 2);
      expect(result.map((r) => r.id), containsAll([1, 2]));
    });

    test('filters by Yesterday date preset correctly', () {
      final state = const HistoryFilterState().copyWith(
        datePreset: HistoryDatePreset.yesterday,
      );
      final result = filterHistoryReadings(sampleReadings, state);
      expect(result.length, 1);
      expect(result.first.id, 3);
    });

    test('filters by Past 7 Days correctly', () {
      final state = const HistoryFilterState().copyWith(
        datePreset: HistoryDatePreset.past7Days,
      );
      final result = filterHistoryReadings(sampleReadings, state);
      expect(result.length, 4);
      expect(result.map((r) => r.id), containsAll([1, 2, 3, 4]));
    });

    test('filters by Past 30 Days correctly', () {
      final state = const HistoryFilterState().copyWith(
        datePreset: HistoryDatePreset.past30Days,
      );
      final result = filterHistoryReadings(sampleReadings, state);
      expect(result.length, 5);
      expect(result.any((r) => r.id == 6), isFalse);
    });

    test('filters by Custom Date correctly', () {
      final state = const HistoryFilterState().copyWith(
        datePreset: HistoryDatePreset.custom,
        customDate: () => tenDaysAgo,
      );
      final result = filterHistoryReadings(sampleReadings, state);
      expect(result.length, 1);
      expect(result.first.id, 5);
    });

    test('combines vital type and date preset filtering', () {
      final state = const HistoryFilterState(
        selectedVital: VitalType.bloodPressure,
        datePreset: HistoryDatePreset.today,
      );
      final result = filterHistoryReadings(sampleReadings, state);
      expect(result.length, 1);
      expect(result.first.id, 1);
    });
  });

  group('HistoryFilterNotifier state manipulation', () {
    test('initial state has no active filter', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(historyFilterProvider);
      expect(state.hasActiveFilter, isFalse);
      expect(state.activeFilterCount, 0);
      expect(state.selectedVital, isNull);
      expect(state.datePreset, HistoryDatePreset.all);
    });

    test('toggleVital and clearVital work as expected', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(historyFilterProvider.notifier);
      notifier.toggleVital(VitalType.heartRate);
      expect(container.read(historyFilterProvider).selectedVital, VitalType.heartRate);
      expect(container.read(historyFilterProvider).hasActiveFilter, isTrue);
      expect(container.read(historyFilterProvider).activeFilterCount, 1);

      notifier.clearVital();
      expect(container.read(historyFilterProvider).selectedVital, isNull);
      expect(container.read(historyFilterProvider).hasActiveFilter, isFalse);
    });

    test('reset clears both vital and date filters', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(historyFilterProvider.notifier);
      notifier.selectVital(VitalType.bloodGlucose);
      notifier.setDatePreset(HistoryDatePreset.past7Days);
      expect(container.read(historyFilterProvider).hasActiveFilter, isTrue);
      expect(container.read(historyFilterProvider).activeFilterCount, 2);

      notifier.reset();
      expect(container.read(historyFilterProvider).hasActiveFilter, isFalse);
      expect(container.read(historyFilterProvider).activeFilterCount, 0);
      expect(container.read(historyFilterProvider).selectedVital, isNull);
      expect(container.read(historyFilterProvider).datePreset, HistoryDatePreset.all);
    });
  });

  group('HistoryFilterBar and HistoryFilterSheet widget tests', () {
    testWidgets('renders compact bar with count and Filter button', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: HistoryFilterBar(
                totalCount: 10,
                filteredCount: 10,
              ),
            ),
          ),
        ),
      );

      // Verify log count and buttons
      expect(find.text('10 recorded logs'), findsOneWidget);
      expect(find.text('Hide Voice'), findsOneWidget);
      expect(find.text('Filter'), findsOneWidget);
    });

    testWidgets('tapping Voice toggle button toggles voice transcript visibility', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: HistoryFilterBar(
                totalCount: 5,
                filteredCount: 5,
              ),
            ),
          ),
        ),
      );

      // Initially on ("Hide Voice")
      expect(find.text('Hide Voice'), findsOneWidget);
      expect(container.read(showVoiceTranscriptProvider), isTrue);

      // Tap to toggle off
      await tester.tap(find.text('Hide Voice'));
      await tester.pumpAndSettle();

      expect(find.text('Unhide Voice'), findsOneWidget);
      expect(container.read(showVoiceTranscriptProvider), isFalse);

      // Tap again to toggle back on
      await tester.tap(find.text('Unhide Voice'));
      await tester.pumpAndSettle();

      expect(find.text('Hide Voice'), findsOneWidget);
      expect(container.read(showVoiceTranscriptProvider), isTrue);
    });

    testWidgets('tapping Filter button opens HistoryFilterSheet with options', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: HistoryFilterBar(
                totalCount: 15,
                filteredCount: 15,
              ),
            ),
          ),
        ),
      );

      // Tap Filter button
      await tester.tap(find.text('Filter'));
      await tester.pumpAndSettle();

      // Verify bottom sheet appears
      expect(find.text('Filter Logs'), findsOneWidget);
      expect(find.text('VITAL SIGN'), findsOneWidget);
      expect(find.text('DATE RANGE'), findsOneWidget);
      expect(find.text('All Vitals'), findsOneWidget);
      expect(find.text('Blood Pressure'), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);

      // Select Blood Pressure
      await tester.tap(find.text('Blood Pressure'));
      await tester.pumpAndSettle();

      // Tap Apply / Show Results button
      await tester.tap(find.textContaining('Show'));
      await tester.pumpAndSettle();

      // Filter sheet closed, filter is applied
      expect(container.read(historyFilterProvider).selectedVital, VitalType.bloodPressure);
      expect(find.text('Blood Pressure'), findsOneWidget); // In active tags
      expect(find.text('Clear all'), findsOneWidget);
    });
  });
}
