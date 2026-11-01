import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medi_cord/app.dart';
import 'package:medi_cord/core/vitals/vital_type.dart';
import 'package:medi_cord/data/models/vital_reading.dart';
import 'package:medi_cord/speech/speech_service.dart';
import 'package:medi_cord/data/repositories/vital_repository.dart';
import 'package:medi_cord/features/record/record_controller.dart';
import 'package:medi_cord/features/record/widgets/mic_button.dart';
import 'package:medi_cord/features/record/widgets/review_card.dart';

class FakeSpeechService implements SpeechService {
  void Function(String text, bool isFinal)? onResultCallback;

  @override
  Future<bool> initialize() async => true;

  @override
  bool get isAvailable => true;

  @override
  bool get isListening => true;

  @override
  Future<void> startListening({
    required void Function(String text, bool isFinal) onResult,
    void Function(double soundLevel)? onSoundLevel,
  }) async {
    onResultCallback = onResult;
  }

  @override
  Future<String> stopListening() async => '';

  @override
  Future<void> cancelListening() async {}
}

// In-memory mock repository for tests
class FakeVitalRepository extends VitalRepository {
  final List<VitalReading> _storage = [];

  @override
  Future<VitalReading> insertReading(VitalReading reading) async {
    final withId = reading.copyWith(id: _storage.length + 1);
    _storage.insert(0, withId);
    return withId;
  }

  @override
  Future<List<VitalReading>> getAllReadings() async {
    return List.unmodifiable(_storage);
  }

  @override
  Future<List<VitalReading>> getReadingsByType(VitalType type) async {
    return _storage.where((r) => r.type == type).toList();
  }

  @override
  Future<List<VitalReading>> getReadingsForRange({
    required VitalType type,
    required DateTime start,
    required DateTime end,
  }) async {
    final list = _storage.where((r) {
      if (r.type != type) return false;
      return !r.recordedAt.isBefore(start) && !r.recordedAt.isAfter(end);
    }).toList();
    list.sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
    return list;
  }

  @override
  Future<int> deleteReading(int id) async {
    _storage.removeWhere((r) => r.id == id);
    return 1;
  }

  @override
  Future<int> clearAll() async {
    final count = _storage.length;
    _storage.clear();
    return count;
  }
}

void main() {
  testWidgets('App renders MediCord, mic button, and user guide in idle state', (tester) async {
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

    expect(find.byType(Image), findsOneWidget);
    expect(find.byType(MicButton), findsOneWidget);
    expect(find.text('Press and hold to record'), findsOneWidget);
    expect(find.text('Reserved Voice Keywords'), findsOneWidget);
    expect(find.text('How to Use MediCord'), findsOneWidget);
    expect(find.text('Press & Hold'), findsOneWidget);
  });

  testWidgets('Simulated voice input shows Review Card with Retry and Save buttons',
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

    // Trigger simulated voice input
    final container = ProviderScope.containerOf(tester.element(find.byType(MediCordApp)));
    container.read(recordControllerProvider.notifier).simulateSpeechInput('Glucose 120');
    await tester.pumpAndSettle();

    // Verify Review Card appears with spoken transcript and parsed values
    expect(find.byType(ReviewCard), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is RichText &&
            w.text.toPlainText().contains('You spoke: "Glucose 120"'),
      ),
      findsOneWidget,
    );
    expect(find.text('Blood Glucose'), findsOneWidget);
    expect(find.text('120 mg/dL'), findsOneWidget);

    // Verify Retry and Save buttons exist
    final retryFinder = find.widgetWithText(OutlinedButton, 'Retry');
    final saveFinder = find.widgetWithText(FilledButton, 'Save');
    expect(retryFinder, findsOneWidget);
    expect(saveFinder, findsOneWidget);

    // Ensure save button is visible in scroll view and tap
    await tester.ensureVisible(saveFinder);
    await tester.tap(saveFinder);
    await tester.pumpAndSettle();

    // Review card should disappear and return to idle
    expect(find.byType(ReviewCard), findsNothing);
    expect(find.text('Press and hold to record'), findsOneWidget);

    // Switch to History tab and verify saved reading is displayed
    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();

    expect(find.text('Blood Glucose'), findsOneWidget);
    expect(find.text('120 mg/dL'), findsOneWidget);
    expect(find.text('"Glucose 120"'), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('1 log'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
  });

  testWidgets('Retry button discards recording and returns to idle', (tester) async {
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

    // Trigger simulated voice input
    final container = ProviderScope.containerOf(tester.element(find.byType(MediCordApp)));
    container.read(recordControllerProvider.notifier).simulateSpeechInput('BP 120 over 80');
    await tester.pumpAndSettle();

    expect(find.byType(ReviewCard), findsOneWidget);
    expect(find.text('120 / 80 mmHg'), findsOneWidget);

    // Tap Retry
    final retryFinder = find.widgetWithText(OutlinedButton, 'Retry');
    await tester.ensureVisible(retryFinder);
    await tester.tap(retryFinder);
    await tester.pumpAndSettle();

    expect(find.byType(ReviewCard), findsNothing);
    expect(find.text('Press and hold to record'), findsOneWidget);
  });

  testWidgets('Theme toggle switch toggles between Light and Dark theme', (tester) async {
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

    // Initially in Light mode
    expect(find.text('Light'), findsOneWidget);

    // Tap theme toggle switch
    await tester.tap(find.text('Light'));
    await tester.pumpAndSettle();

    // Now switched to Dark mode
    expect(find.text('Dark'), findsOneWidget);

    // Tap again to switch back
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();

    expect(find.text('Light'), findsOneWidget);
  });

  testWidgets('Text size button opens sheet and allows user to change text size', (tester) async {
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

    // Find and tap the TextSizeButton
    final textSizeBtn = find.byTooltip('Text Size (Standard)');
    expect(textSizeBtn, findsOneWidget);
    await tester.tap(textSizeBtn);
    await tester.pumpAndSettle();

    // Verify modal sheet appears with options
    expect(find.text('App Text Size'), findsOneWidget);
    expect(find.text('Large'), findsOneWidget);
    expect(find.text('Extra Large'), findsOneWidget);
    expect(find.text('Maximum'), findsOneWidget);

    // Select Extra Large
    await tester.tap(find.text('Extra Large'));
    await tester.pumpAndSettle();

    // Tap Done
    await tester.ensureVisible(find.text('Done'));
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    // Tooltip should now reflect Extra Large and badge should be present
    expect(find.byTooltip('Text Size (Extra Large)'), findsOneWidget);
    expect(find.text('1.4x'), findsOneWidget);
  });

  test('RecordController automatically recovers when complete transcript arrives late', () async {
    final fakeSpeech = FakeSpeechService();
    final container = ProviderContainer(
      overrides: [
        speechServiceProvider.overrideWithValue(fakeSpeech),
        vitalRepositoryProvider.overrideWithValue(FakeVitalRepository()),
      ],
    );

    final controller = container.read(recordControllerProvider.notifier);

    // 1. User presses down
    await controller.onMicPressDown();
    expect(container.read(recordControllerProvider).status, RecordStatus.listening);

    // 2. Partial incomplete transcript arrives
    fakeSpeech.onResultCallback?.call('blood pressure 120', false);
    expect(container.read(recordControllerProvider).rawTranscript, 'blood pressure 120');

    // 3. User releases mic immediately
    final releaseFuture = controller.onMicPressUp();

    // 4. While processing (or after early cutoff), complete transcript arrives from speech engine
    fakeSpeech.onResultCallback?.call('blood pressure 120 over 80', true);

    await releaseFuture;

    // 5. Must automatically transition to review with parsed values
    final state = container.read(recordControllerProvider);
    expect(state.status, RecordStatus.review);
    expect(state.parsedReading, isNotNull);
    expect(state.parsedReading!.primaryValue, 120);
    expect(state.parsedReading!.secondaryValue, 80);
  });
}
