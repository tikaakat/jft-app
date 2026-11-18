import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:jft_prep/config.dart';
import 'package:jft_prep/logic/session.dart';
import 'package:jft_prep/models/question.dart';

Question q(String id, {int answer = 0}) => Question(
      id: id,
      category: Section.vocab,
      level: 'A2',
      text: 't',
      choices: const ['a', 'b', 'c', 'd'],
      answer: answer,
      explanation: const {'en': 'e'},
    );

void main() {
  test('shuffle keeps the correct choice correct', () {
    final rng = Random(1);
    for (var i = 0; i < 200; i++) {
      final s = q('x', answer: 2).shuffled(rng);
      expect(s.choices[s.answer], 'c');
      expect(s.choices.toSet(), {'a', 'b', 'c', 'd'});
    }
  });

  test('correct position is not biased even if data always uses index 0', () {
    final rng = Random(42);
    final counts = List.filled(4, 0);
    const n = 40000;
    for (var i = 0; i < n; i++) {
      counts[q('x').shuffled(rng).answer]++;
    }
    for (final c in counts) {
      expect(c / n, closeTo(0.25, 0.015), reason: '$counts');
    }
  });

  test('free session = first kFreeLimitPerCategory questions', () {
    final pool = [for (var i = 0; i < 30; i++) q('q$i')];
    final s = buildSession(pool, premium: false, rng: Random(3));
    expect(s.length, kFreeLimitPerCategory);
    expect(s.map((e) => e.id).toSet(),
        {for (var i = 0; i < kFreeLimitPerCategory; i++) 'q$i'});
  });

  test('premium session draws kQuestionsPerSession distinct questions', () {
    final pool = [for (var i = 0; i < 30; i++) q('q$i')];
    final s = buildSession(pool, premium: true, rng: Random(3));
    expect(s.length, kQuestionsPerSession);
    expect(s.map((e) => e.id).toSet().length, kQuestionsPerSession);
  });

  test('explanation accepts legacy string format', () {
    final parsed = Question.fromJson({
      'id': 'v1',
      'category': 'vocab',
      'text': 't',
      'choices': ['a', 'b', 'c', 'd'],
      'answer': 1,
      'explanation': 'old english string',
    });
    expect(parsed.explanationFor('ne'), 'old english string');
  });
}
