import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:jft_prep/data/question_source.dart';
import 'package:jft_prep/logic/ruby.dart';
import 'package:jft_prep/models/question.dart';

/// Validates assets/questions.json. Run before every release.
void main() {
  final raw = File('assets/questions.json').readAsStringSync();
  final qs = parseQuestions(raw);

  test('ids are unique', () {
    final ids = qs.map((q) => q.id).toList();
    expect(ids.toSet().length, ids.length);
  });

  test('each question has 4 distinct choices and an English explanation', () {
    for (final q in qs) {
      expect(q.choices.length, 4, reason: q.id);
      expect(q.choices.toSet().length, 4, reason: '${q.id} duplicate choice');
      expect(q.explanation['en'], isNotEmpty, reason: q.id);
      expect(q.text.trim(), isNotEmpty, reason: q.id);
    }
  });

  test('furigana markup is valid and choices stay distinct without it', () {
    for (final q in qs) {
      final texts = [
        q.text,
        if (q.passage != null) q.passage!,
        ...q.choices,
        ...q.script.map((l) => l.text),
      ];
      for (final t in texts) {
        expect(isValidRuby(t), isTrue, reason: '${q.id}: $t');
      }
      expect(
        q.choices.map(plainText).toSet().length,
        q.choices.length,
        reason: q.id,
      );
    }
  });

  test('kanji reading/writing questions never show furigana', () {
    for (final q in qs.where(
      (q) => q.text.contains('の 読み方は') || q.text.contains('漢字で どう 書きますか'),
    )) {
      expect(q.noFurigana, isTrue, reason: q.id);
    }
  });

  test('listening has a script, reading has a passage', () {
    for (final q in qs) {
      if (q.category == Section.listen) {
        expect(q.script, isNotEmpty, reason: q.id);
      }
      if (q.category == Section.read) {
        expect(q.passage, isNotNull, reason: q.id);
      }
    }
  });

  test('at least 30 questions per section (Phase 1 target)', () {
    for (final c in Section.values) {
      expect(
        qs.where((q) => q.category == c).length,
        greaterThanOrEqualTo(30),
        reason: c.name,
      );
    }
  });

  test('report unreviewed drafts', () {
    final drafts = qs.where((q) => !q.reviewed).map((q) => q.id).toList();
    // Not a failure: release builds hide drafts automatically.
    // ignore: avoid_print
    print('Unreviewed drafts: ${drafts.length}/${qs.length}');
  });
}
