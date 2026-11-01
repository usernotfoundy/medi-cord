import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medi_cord/app.dart';
import 'package:medi_cord/core/vitals/vital_type.dart';
import 'package:medi_cord/data/models/vital_reading.dart';
import 'package:medi_cord/features/analytics/models/analytics_models.dart';
import 'package:medi_cord/features/analytics/widgets/clinical_kpi_grid.dart';
import 'package:medi_cord/features/analytics/widgets/clinical_trend_chart.dart';
import 'package:medi_cord/features/analytics/widgets/time_range_selector.dart';
import 'package:medi_cord/features/analytics/widgets/vital_type_selector.dart';
import 'package:medi_cord/features/record/record_controller.dart';
import 'widget_test.dart';

void main() {
  group('Analytics Models & Computations', () {
    test('TimeOfDaySlot categorizes timestamps accurately', () {
      final morning = DateTime(2026, 11, 1, 8, 30);
      final noon = DateTime(2026, 11, 1, 13, 0);
      final evening = DateTime(2026, 11, 1, 20, 15);
      final lateNight = DateTime(2026, 11, 1, 2, 0);

      expect(TimeOfDaySlot.fromDateTime(morning), TimeOfDaySlot.am);
      expect(TimeOfDaySlot.fromDateTime(noon), TimeOfDaySlot.midday);
      expect(TimeOfDaySlot.fromDateTime(evening), TimeOfDaySlot.pm);
      expect(TimeOfDaySlot.fromDateTime(lateNight), TimeOfDaySlot.pm);
    });

    test('TargetZone evaluates Blood Pressure correctly', () {
      // Normal BP: 118 / 76
      final normal = VitalReading(
        type: VitalType.bloodPressure,
        valuePrimary: 118,
        valueSecondary: 76,
        unit: 'mmHg',
        rawTranscript: '118 76',
        recordedAt: DateTime.now(),
      );
      expect(TargetZone.evaluate(normal), TargetZone.inTarget);

      // Elevated: 125 / 78
      final elevated = VitalReading(
        type: VitalType.bloodPressure,
        valuePrimary: 125,
        valueSecondary: 78,
        unit: 'mmHg',
        rawTranscript: '125 78',
        recordedAt: DateTime.now(),
      );
      expect(TargetZone.evaluate(elevated), TargetZone.elevated);

      // Alert / Hypertensive: 145 / 92
      final alert = VitalReading(
        type: VitalType.bloodPressure,
        valuePrimary: 145,
        valueSecondary: 92,
        unit: 'mmHg',
        rawTranscript: '145 92',
        recordedAt: DateTime.now(),
      );
      expect(TargetZone.evaluate(alert), TargetZone.critical);
    });

    test('AnalyticsSummary.calculate produces precise clinical metrics', () {
      final readings = [
        // Morning reading (in-target)
        VitalReading(
          id: 1,
          type: VitalType.bloodPressure,
          valuePrimary: 118,
          valueSecondary: 76,
          valueTertiary: 72,
          unit: 'mmHg',
          rawTranscript: '118 76 72',
          recordedAt: DateTime(2026, 11, 1, 8, 0),
        ),
        // Evening reading (elevated)
        VitalReading(
          id: 2,
          type: VitalType.bloodPressure,
          valuePrimary: 128,
          valueSecondary: 82,
          valueTertiary: 78,
          unit: 'mmHg',
          rawTranscript: '128 82 78',
          recordedAt: DateTime(2026, 11, 1, 19, 0),
        ),
      ];

      final summary = AnalyticsSummary.calculate(
        VitalType.bloodPressure,
        readings,
      );

      expect(summary.totalCount, 2);
      expect(summary.meanPrimary, 123.0); // (118 + 128) / 2
      expect(summary.meanSecondary, 79.0); // (76 + 82) / 2
      expect(summary.meanTertiary, 75.0); // (72 + 78) / 2
      expect(summary.minPrimary, 118.0);
      expect(summary.maxPrimary, 128.0);
      expect(summary.inTargetPercentage, 50.0);
      expect(summary.amCount, 1);
      expect(summary.pmCount, 1);
      expect(summary.amMeanPrimary, 118.0);
      expect(summary.pmMeanPrimary, 128.0);
    });

    test('AnalyticsSummary handles empty readings gracefully', () {
      final summary = AnalyticsSummary.calculate(
        VitalType.heartRate,
        [],
      );

      expect(summary.isEmpty, true);
      expect(summary.totalCount, 0);
      expect(summary.meanPrimary, isNull);
      expect(summary.inTargetPercentage, 0.0);
    });
  });

  group('Analytics UI & Navigation Widget Tests', () {
    testWidgets('Can navigate to Analytics tab and view selectors & empty state',
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

      // Find bottom navigation bar Analytics destination
      final analyticsTab = find.text('Analytics');
      expect(analyticsTab, findsOneWidget);
      await tester.tap(analyticsTab);
      await tester.pumpAndSettle();

      // Verify Analytics Screen elements
      expect(find.text('Clinical Analytics'), findsOneWidget);
      expect(find.byType(VitalTypeSelector), findsOneWidget);
      expect(find.byType(TimeRangeSelector), findsOneWidget);

      // Verify default presets are visible
      expect(find.text('Day'), findsOneWidget);
      expect(find.text('7 Days'), findsOneWidget);
      expect(find.text('30 Days'), findsOneWidget);
      expect(find.text('90 Days'), findsOneWidget);

      // Empty state prompt
      expect(find.text('No Blood Pressure Records Found'), findsOneWidget);
    });

    testWidgets('Populated readings display Clinical KPI Grid and Chart',
        (tester) async {
      final fakeRepo = FakeVitalRepository();
      final now = DateTime.now();

      // Add two blood pressure readings within today
      await fakeRepo.insertReading(
        VitalReading(
          type: VitalType.bloodPressure,
          valuePrimary: 120,
          valueSecondary: 80,
          valueTertiary: 72,
          unit: 'mmHg',
          rawTranscript: '120 80 72',
          recordedAt: now.subtract(const Duration(hours: 3)),
        ),
      );
      await fakeRepo.insertReading(
        VitalReading(
          type: VitalType.bloodPressure,
          valuePrimary: 130,
          valueSecondary: 85,
          valueTertiary: 76,
          unit: 'mmHg',
          rawTranscript: '130 85 76',
          recordedAt: now.subtract(const Duration(hours: 1)),
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            vitalRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: const MediCordApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to Analytics tab
      await tester.tap(find.text('Analytics'));
      await tester.pumpAndSettle();

      // Verify KPI grid & trend chart rendered
      expect(find.byType(ClinicalKpiGrid), findsOneWidget);
      expect(find.byType(ClinicalTrendChart), findsOneWidget);
      expect(find.text('IN TARGET RANGE'), findsOneWidget);
      expect(find.text('PERIOD AVERAGE'), findsOneWidget);
      expect(find.text('LATEST READING'), findsOneWidget);
    });
  });
}
