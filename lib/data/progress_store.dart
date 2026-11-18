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
