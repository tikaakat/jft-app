import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jft_prep/app_services.dart';
import 'package:jft_prep/config.dart';
import 'package:jft_prep/data/progress_store.dart';
import 'package:jft_prep/data/question_source.dart';
import 'package:jft_prep/main.dart';
import 'package:jft_prep/models/question.dart';
import 'package:jft_prep/services/purchase_service.dart';
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

class FakePurchases implements PurchaseService {
  FakePurchases({
    bool premium = false,
    this.offered = true,
    this.restorable = false,
  }) : _premium = ValueNotifier(premium);

  final ValueNotifier<bool> _premium;
  final bool offered;
  final bool restorable;
  int buys = 0;

  @override
  ValueListenable<bool> get isPremium => _premium;
  @override
  bool get available => offered;
  @override
  Future<void> init() async {}
  @override
  Future<List<Plan>> plans() async => offered
      ? const [
          Plan(id: 'annual', period: PlanPeriod.yearly, price: r'$6.99'),
          Plan(id: 'monthly', period: PlanPeriod.monthly, price: r'$0.99'),
        ]
      : const [];
  @override
  Future<BuyResult> buy(Plan plan) async {
    buys++;
    _premium.value = true;
    return BuyResult.success;
  }

  @override
  Future<bool> restore() async {
    if (restorable) _premium.value = true;
    return _premium.value;
  }
}

class FileSource implements QuestionSource {
  @override
  Future<List<Question>> load() async =>
      parseQuestions(File('assets/questions.json').readAsStringSync());
}

Future<AppServices> services({
  bool premium = false,
  Map<String, Object> prefs = const {},
  FakePurchases? purchases,
  FakeSpeaker? speaker,
}) async {
  SharedPreferences.setMockInitialValues(Map.of(prefs));
  final store = await ProgressStore.open();
  return AppServices(
    store: store,
    speaker: speaker ?? FakeSpeaker(),
    purchases: purchases ?? FakePurchases(premium: premium),
  );
}

Future<void> tapScrolling(WidgetTester tester, Key key) async {
  await tester.scrollUntilVisible(
    find.byKey(key),
    200,
    scrollable: find.byType(Scrollable).last,
  );
  await tester.tap(find.byKey(key));
  await tester.pumpAndSettle();
}

/// Answers every question of the open quiz (always picks choice 0) and
/// stops at the result dialog. Returns the number of answered questions.
Future<int> answerAll(WidgetTester tester) async {
  var answered = 0;
  while (true) {
    await tapScrolling(tester, const Key('choice_0'));
    answered++;
    await tapScrolling(tester, const Key('next'));
    if (find.byKey(const Key('result_home')).evaluate().isNotEmpty) break;
  }
  return answered;
}

/// [answerAll], then back to home via the result dialog.
Future<int> playThrough(WidgetTester tester) async {
  final n = await answerAll(tester);
  await tester.tap(find.byKey(const Key('result_home')));
  await tester.pumpAndSettle();
  return n;
}

Future<void> pumpApp(
  WidgetTester tester,
  AppServices s, {
  bool includeDrafts = true,
}) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.75;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    JftApp(source: FileSource(), services: s, includeDrafts: includeDrafts),
  );
  await tester.pumpAndSettle();
}

Future<void> openSection(WidgetTester tester, Section c) async {
  await tester.ensureVisible(find.byKey(Key('card_${c.name}')));
  await tester.tap(find.byKey(Key('card_${c.name}')));
  await tester.pumpAndSettle();
}

void main() {
  for (final premium in [false, true]) {
    testWidgets('every section can be finished (premium=$premium)', (
      tester,
    ) async {
      final speaker = FakeSpeaker();
      final s = await services(premium: premium, speaker: speaker);
      await pumpApp(tester, s);

      for (final c in Section.values) {
        await openSection(tester, c);
        final n = await playThrough(tester);
        expect(n, premium ? kQuestionsPerSession : kFreeLimitPerCategory);
        expect(s.store.bestPercent(c), inInclusiveRange(0, 100));
      }
      expect(speaker.calls, greaterThan(0)); // listening used TTS
      expect(find.textContaining('Best: –'), findsNothing);
    });
  }

  testWidgets('drafts are hidden when includeDrafts is false', (tester) async {
    await pumpApp(tester, await services(), includeDrafts: false);
    expect(find.textContaining('Mastered 0 / 0'), findsNWidgets(4));
  });

  testWidgets('review lists mistakes and retrying resolves them', (
    tester,
  ) async {
    final s = await services(
      premium: true,
      prefs: {
        'wrong_vocab': ['v001', 'v002', 'v003'],
        'wrong_read': ['r001'],
      },
    );
    await pumpApp(tester, s);

    expect(find.text('4'), findsOneWidget); // badge
    await tester.tap(find.byKey(const Key('open_review')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Script and Vocabulary (3)'), findsOneWidget);
    expect(find.textContaining('Reading Comprehension (1)'), findsOneWidget);

    await tester.tap(find.byKey(const Key('review_vocab')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Review:'), findsOneWidget);
    expect(await playThrough(tester), 3);

    final stillWrong = s.store.wrong(Section.vocab);
    final mastered = s.store.mastered(Section.vocab);
    for (final id in ['v001', 'v002', 'v003']) {
      expect(
        stillWrong.contains(id) != mastered.contains(id),
        isTrue,
        reason: id,
      );
    }
    expect(s.store.answeredCount(Section.vocab), 3);
    expect(s.store.bestPercent(Section.vocab), -1);
  });

  testWidgets('summary shows accuracy after answering', (tester) async {
    await pumpApp(
      tester,
      await services(prefs: {'answered_conv': 4, 'correct_conv': 3}),
    );
    expect(find.text('75%'), findsOneWidget);
    expect(find.textContaining('Accuracy: 75%'), findsOneWidget);
  });

  testWidgets('free user: quiz end -> paywall -> purchase unlocks full set', (
    tester,
  ) async {
    final purchases = FakePurchases();
    final s = await services(purchases: purchases);
    await pumpApp(tester, s);

    await openSection(tester, Section.vocab);
    await answerAll(tester);
    expect(find.textContaining('finished the free questions'), findsOneWidget);
    await tester.tap(find.byKey(const Key('result_premium')));
    await tester.pumpAndSettle();

    expect(find.textContaining(r'$6.99 / year'), findsOneWidget);
    expect(find.textContaining(r'$0.99 / month'), findsOneWidget);
    await tester.tap(find.byKey(const Key('subscribe')));
    await tester.pumpAndSettle();
    expect(purchases.buys, 1);

    // Back in the quiz with the full premium session.
    expect(find.text('Question 1 / $kQuestionsPerSession'), findsOneWidget);
  });

  testWidgets('paywall says billing unavailable without offerings', (
    tester,
  ) async {
    final s = await services(purchases: FakePurchases(offered: false));
    await pumpApp(tester, s);
    await tester.tap(find.byKey(const Key('home_unlock')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('billing_unavailable')), findsOneWidget);
  });

  testWidgets('restore from settings activates premium', (tester) async {
    final s = await services(purchases: FakePurchases(restorable: true));
    await pumpApp(tester, s);
    await tester.tap(find.byKey(const Key('open_settings')));
    await tester.pumpAndSettle();
    expect(find.text('Not subscribed'), findsOneWidget);
    await tester.tap(find.byKey(const Key('settings_restore')));
    await tester.pumpAndSettle();
    expect(find.text('Active'), findsOneWidget);
    expect(find.text('Premium restored.'), findsOneWidget);
  });

  testWidgets('switching UI language to Indonesian translates and persists', (
    tester,
  ) async {
    final s = await services();
    await pumpApp(tester, s);
    await tester.tap(find.byKey(const Key('open_settings')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('lang_id')));
    await tester.pumpAndSettle();

    expect(find.text('Pengaturan'), findsOneWidget); // "Settings"
    expect(find.textContaining('terjemahan mesin'), findsOneWidget);
    expect(s.store.uiLanguage, 'id');

    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();
    expect(find.text('Huruf dan Kosakata'), findsOneWidget);
  });

  testWidgets('furigana switch persists', (tester) async {
    final s = await services();
    await pumpApp(tester, s);
    expect(s.furigana.value, isTrue); // default on
    await tester.tap(find.byKey(const Key('open_settings')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('furigana_switch')),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.byKey(const Key('furigana_switch')));
    await tester.pumpAndSettle();
    expect(s.store.furigana, isFalse);
  });

  test('unsupported system locale falls back to English', () {
    expect(JftApp.resolveLocale(null, const Locale('fr')), const Locale('en'));
    expect(
      JftApp.resolveLocale(null, const Locale('ne', 'NP')),
      const Locale('ne'),
    );
    expect(JftApp.resolveLocale('vi', const Locale('id')), const Locale('vi'));
  });
}
