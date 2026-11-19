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

  testWidgets('review lists mistakes and retrying resolves them',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'premium': true,
      'wrong_vocab': ['v001', 'v002', 'v003'],
      'wrong_read': ['r001'],
    });
    final store = await ProgressStore.open();
    await pumpApp(tester, store, FakeSpeaker());

    // Badge on home shows the total number of mistakes.
    expect(find.text('4'), findsOneWidget);
    await tester.tap(find.byKey(const Key('open_review')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Script and Vocabulary (3)'), findsOneWidget);
    expect(find.textContaining('Reading Comprehension (1)'), findsOneWidget);

    await tester.tap(find.byKey(const Key('review_vocab')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Review:'), findsOneWidget);
    final n = await playThrough(tester);
    expect(n, 3); // exactly the mistakes, not a normal session

    // Every retried question is either still wrong or newly mastered.
    final stillWrong = store.wrong(Section.vocab);
    final mastered = store.mastered(Section.vocab);
    for (final id in ['v001', 'v002', 'v003']) {
      expect(stillWrong.contains(id) != mastered.contains(id), isTrue,
          reason: id);
    }
    expect(store.answeredCount(Section.vocab), 3);
    expect(store.bestPercent(Section.vocab), -1); // review doesn't set best
  });

  testWidgets('summary shows accuracy after answering', (tester) async {
    SharedPreferences.setMockInitialValues({
      'answered_conv': 4,
      'correct_conv': 3,
    });
    final store = await ProgressStore.open();
    await pumpApp(tester, store, FakeSpeaker());
    expect(find.text('75%'), findsOneWidget);
    expect(find.textContaining('Accuracy: 75%'), findsOneWidget);
  });
}
