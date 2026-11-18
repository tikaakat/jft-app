import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:jft_prep/data/question_source.dart';
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
      expect(qs.where((q) => q.category == c).length,
          greaterThanOrEqualTo(30), reason: c.name);
    }
  });

  test('report unreviewed drafts', () {
    final drafts = qs.where((q) => !q.reviewed).map((q) => q.id).toList();
    // Not a failure: release builds hide drafts automatically.
    // ignore: avoid_print
    print('Unreviewed drafts: ${drafts.length}/${qs.length}');
  });
}
