import 'dart:math';

import '../config.dart';
import '../models/question.dart';

/// Builds the question list for one quiz session.
///
/// Free users always get the first [kFreeLimitPerCategory] questions of the
/// category (a stable "free sample"). Premium users get a random draw of up
/// to [kQuestionsPerSession]. Choices are always shuffled.
List<Question> buildSession(
  List<Question> pool, {
  required bool premium,
  Random? rng,
}) {
  final r = rng ?? Random();
  final picked = premium
      ? (List<Question>.of(pool)..shuffle(r)).take(kQuestionsPerSession)
      : (pool.take(kFreeLimitPerCategory).toList()..shuffle(r));
  return [for (final q in picked) q.shuffled(r)];
}
