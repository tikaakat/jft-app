import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../config.dart';
import '../models/question.dart';

/// Where questions come from. Swap [AssetQuestionSource] for a remote
/// implementation later without touching the UI.
abstract class QuestionSource {
  Future<List<Question>> load();
}

class AssetQuestionSource implements QuestionSource {
  const AssetQuestionSource([this.path = 'assets/questions.json']);
  final String path;

  @override
  Future<List<Question>> load() async =>
      parseQuestions(await rootBundle.loadString(path));
}

/// Parses the questions JSON. Accepts either a bare list or
/// `{"version": n, "questions": [...]}` (the shape a remote feed would use).
List<Question> parseQuestions(String raw) {
  final decoded = jsonDecode(raw);
  final list = decoded is List ? decoded : (decoded as Map)['questions'] as List;
  return list.map((e) => Question.fromJson(e as Map<String, dynamic>)).toList();
}

/// Holds all questions grouped by category, hiding unreviewed drafts in
/// release builds.
class QuestionBank {
  QuestionBank(List<Question> all, {bool? includeDrafts})
      : _byCategory = {
          for (final c in Section.values)
            c: all
                .where((q) => q.category == c)
                .where((q) =>
                    q.reviewed ||
                    (includeDrafts ?? (kDebugMode || kIncludeDraftsDefine)))
                .toList(),
        };

  final Map<Section, List<Question>> _byCategory;

  List<Question> of(Section c) => _byCategory[c] ?? const [];

  Question? byId(String id) {
    for (final list in _byCategory.values) {
      for (final q in list) {
        if (q.id == id) return q;
      }
    }
    return null;
  }
}
