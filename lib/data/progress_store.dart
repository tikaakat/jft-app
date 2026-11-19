import 'package:shared_preferences/shared_preferences.dart';

import '../models/question.dart';

/// Local persistence for scores and per-question progress.
class ProgressStore {
  ProgressStore(this._prefs);
  final SharedPreferences _prefs;

  static Future<ProgressStore> open() async =>
      ProgressStore(await SharedPreferences.getInstance());

  /// Best score of a session, in percent (0-100). -1 if never played.
  int bestPercent(Section c) => _prefs.getInt('best_${c.name}') ?? -1;

  /// Ids answered correctly at least once.
  Set<String> mastered(Section c) =>
      (_prefs.getStringList('mastered_${c.name}') ?? const []).toSet();

  /// Ids whose latest answer was wrong (for the review screen, Phase 1.5).
  Set<String> wrong(Section c) =>
      (_prefs.getStringList('wrong_${c.name}') ?? const []).toSet();

  /// Total answers given / correct answers in this section (for accuracy).
  int answeredCount(Section c) => _prefs.getInt('answered_${c.name}') ?? 0;
  int correctCount(Section c) => _prefs.getInt('correct_${c.name}') ?? 0;

  /// Selected UI language code, or null to follow the system.
  String? get uiLanguage => _prefs.getString('ui_lang');
  Future<void> setUiLanguage(String? code) => code == null
      ? _prefs.remove('ui_lang')
      : _prefs.setString('ui_lang', code);

  /// Show furigana over kanji (default on for beginners).
  bool get furigana => _prefs.getBool('furigana') ?? true;
  Future<void> setFurigana(bool v) => _prefs.setBool('furigana', v);

  /// Cached premium state (the source of truth is the billing service).
  bool get isPremium => _prefs.getBool('premium') ?? false;
  Future<void> setPremium(bool v) => _prefs.setBool('premium', v);

  Future<void> recordAnswer(Question q, bool correct) async {
    final c = q.category;
    final m = mastered(c);
    final w = wrong(c);
    if (correct) {
      m.add(q.id);
      w.remove(q.id);
    } else {
      w.add(q.id);
    }
    await _prefs.setInt('answered_${c.name}', answeredCount(c) + 1);
    if (correct) await _prefs.setInt('correct_${c.name}', correctCount(c) + 1);
    await _prefs.setStringList('mastered_${c.name}', m.toList());
    await _prefs.setStringList('wrong_${c.name}', w.toList());
  }

  /// Saves the session score; returns true if it is a new best.
  Future<bool> recordSession(Section c, int correct, int total) async {
    if (total == 0) return false;
    final pct = (correct * 100 / total).round();
    if (pct > bestPercent(c)) {
      await _prefs.setInt('best_${c.name}', pct);
      return true;
    }
    return false;
  }
}
