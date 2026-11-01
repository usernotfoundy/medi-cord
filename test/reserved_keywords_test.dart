import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medi_cord/app.dart';
import 'package:medi_cord/features/record/record_controller.dart';
import 'package:medi_cord/features/record/widgets/reserved_keywords_modal.dart';
import 'widget_test.dart';

void main() {
  testWidgets('Tapping vital badge in Reserved Voice Keywords opens modal with triggers and Got it button',
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

    // Verify Reserved Voice Keywords section is present
    expect(find.text('Reserved Voice Keywords'), findsOneWidget);

    // Tap on Blood Glucose badge
    final glucoseBadge = find.text('Blood Glucose (mg/dL)');
    expect(glucoseBadge, findsOneWidget);
    await tester.tap(glucoseBadge);
    await tester.pumpAndSettle();

    // Verify ReservedKeywordsModal opened
    expect(find.byType(ReservedKeywordsModal), findsOneWidget);
    expect(find.text('RESERVED VOICE KEYWORDS'), findsOneWidget);

    // Verify triggers for Blood Glucose
    expect(find.text('"glucose"'), findsOneWidget);
    expect(find.text('"sugar"'), findsOneWidget);
    expect(find.text('"blood sugar"'), findsOneWidget);

    // Verify example phrases
    expect(find.text('HOW TO SAY IT (EXAMPLES)'), findsOneWidget);
    expect(find.text('"Glucose 120"'), findsOneWidget);

    // Tap "Got it" button
    final gotItBtn = find.text('Got it');
    expect(gotItBtn, findsOneWidget);
    await tester.tap(gotItBtn);
    await tester.pumpAndSettle();

    // Verify modal is dismissed
    expect(find.byType(ReservedKeywordsModal), findsNothing);
  });
}

