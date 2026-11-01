import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medi_cord/app.dart';
import 'package:medi_cord/core/vitals/vital_type.dart';
import 'package:medi_cord/features/manual_entry/manual_entry_sheet.dart';
import 'package:medi_cord/features/record/record_controller.dart';
import 'widget_test.dart';

void main() {
  testWidgets('Manual Entry opens from Record screen and allows entering past reading',
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

    // Verify shortcut button on Record screen
    final manualBtn = find.text('Forgot to log earlier? Add past reading');
    expect(manualBtn, findsOneWidget);
    await tester.ensureVisible(manualBtn);
    await tester.tap(manualBtn);
    await tester.pumpAndSettle();

    // Verify Manual Entry bottom sheet opened
    expect(find.byType(ManualEntrySheet), findsOneWidget);
    expect(find.text('Manual Vital Entry'), findsOneWidget);
    expect(find.text('RECORDING DATE & TIME'), findsOneWidget);

    // Switch vital to Blood Glucose
    final glucoseChip = find.text('Blood Glucose');
    expect(glucoseChip, findsOneWidget);
    await tester.tap(glucoseChip);
    await tester.pumpAndSettle();

    // Enter glucose value 115
    final valueField = find.byType(TextField).first;
    await tester.enterText(valueField, '115');
    await tester.pumpAndSettle();

    // Enter optional note
    final noteField = find.byType(TextField).last;
    await tester.enterText(noteField, 'Post-breakfast');
    await tester.pumpAndSettle();

    // Tap Save Vital Reading
    final saveBtn = find.text('Save Vital Reading');
    await tester.ensureVisible(saveBtn);
    await tester.tap(saveBtn);
    await tester.pumpAndSettle();

    // Verify saved in fakeRepo
    final readings = await fakeRepo.getAllReadings();
    expect(readings.length, 1);
    expect(readings.first.type, VitalType.glucose);
    expect(readings.first.valuePrimary, 115);
    expect(readings.first.rawTranscript, 'Manual entry');
    expect(readings.first.note, 'Post-breakfast');
  });

  testWidgets('Manual Entry opens from History screen via + button',
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

    // Navigate to History screen
    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();

    // Find and tap '+' button in AppBar
    final addBtn = find.byTooltip('Manual Entry');
    expect(addBtn, findsOneWidget);
    await tester.tap(addBtn);
    await tester.pumpAndSettle();

    // Verify sheet appears
    expect(find.byType(ManualEntrySheet), findsOneWidget);
  });
}
