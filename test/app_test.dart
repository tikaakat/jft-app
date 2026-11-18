import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:jft_prep/config.dart';
import 'package:jft_prep/data/progress_store.dart';
import 'package:jft_prep/data/question_source.dart';
import 'package:jft_prep/main.dart';
import 'package:jft_prep/models/question.dart';
import 'package:jft_prep/services/tts_service.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeSpeaker implements Speaker {
  int calls = 0;
  @override
  Future<bool> speakScript(List<ScriptLine> lines) async {
    calls++;
    return true;
  }

  @override
  Future<void> stop() async {}
}

class FileSource implements QuestionSource {
  @override
  Future<List<Question>> load() async =>
      parseQuestions(File('assets/questions.json').readAsStringSync());
}

Future<ProgressStore> freshStore({bool premium = false}) async {
  SharedPreferences.setMockInitialValues({'premium': premium});
  return ProgressStore.open();
}

Future<void> tapScrolling(WidgetTester tester, Key key) async {
  await tester.scrollUntilVisible(find.byKey(key), 200,
      scrollable: find.byType(Scrollable).last);
  await tester.tap(find.byKey(key));
  await tester.pumpAndSettle();
}

/// Answers every question of the open quiz (always picks choice 0), then
/// returns home via the result dialog.
Future<int> playThrough(WidgetTester tester) async {
  var answered = 0;
  while (true) {
    await tapScrolling(tester, const Key('choice_0'));
    answered++;
    await tapScrolling(tester, const Key('next'));
    await tester.pumpAndSettle();
    if (find.byKey(const Key('result_home')).evaluate().isNotEmpty) break;
  }
  expect(find.text('Result'), findsOneWidget);
  await tester.tap(find.byKey(const Key('result_home')));
  await tester.pumpAndSettle();
  return answered;
}

Future<void> pumpApp(WidgetTester tester, ProgressStore store, Speaker sp) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.75;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(JftApp(
    source: FileSource(),
    store: store,
    speaker: sp,
    includeDrafts: true,
  ));
  await tester.pumpAndSettle();
}

void main() {
  for (final premium in [false, true]) {
    testWidgets('every section can be finished (premium=$premium)',
        (tester) async {
      final store = await freshStore(premium: premium);
      final speaker = FakeSpeaker();
      await pumpApp(tester, store, speaker);

      for (final c in Section.values) {
        await tester.ensureVisible(find.byKey(Key('card_${c.name}')));
        await tester.tap(find.byKey(Key('card_${c.name}')));
        await tester.pumpAndSettle();
        final n = await playThrough(tester);
        expect(n, premium ? kQuestionsPerSession : kFreeLimitPerCategory);
        // Score is saved and shown on the home screen.
        expect(store.bestPercent(c), inInclusiveRange(0, 100));
      }
      expect(speaker.calls, greaterThan(0)); // listening used TTS
      expect(find.textContaining('Best: –'), findsNothing);
    });
  }

  testWidgets('drafts are hidden when includeDrafts is false', (tester) async {
    final store = await freshStore();
    await tester.pumpWidget(JftApp(
      source: FileSource(),
      store: store,
      speaker: FakeSpeaker(),
      includeDrafts: false,
    ));
    await tester.pumpAndSettle();
    expect(find.textContaining('Mastered 0 / 0'), findsNWidgets(4));
  });
}
