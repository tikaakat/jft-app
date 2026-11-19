import 'dart:math';

/// JFT-Basic sections.
enum Section {
  vocab('Script and Vocabulary', '文字と語彙'),
  conv('Conversation and Expression', '会話と表現'),
  listen('Listening Comprehension', '聴解'),
  read('Reading Comprehension', '読解');

  const Section(this.label, this.labelJa);
  final String label;
  final String labelJa;

  static Section parse(String s) => Section.values.firstWhere(
    (c) => c.name == s,
    orElse: () => throw FormatException('Unknown category: $s'),
  );
}

/// One line of a listening script. `speaker` is M (male), F (female)
/// or N (narrator / announcement).
class ScriptLine {
  const ScriptLine(this.speaker, this.text);
  final String speaker;
  final String text;

  factory ScriptLine.fromJson(Map<String, dynamic> j) =>
      ScriptLine(j['speaker'] as String? ?? 'N', j['text'] as String);
}

class Question {
  const Question({
    required this.id,
    required this.category,
    required this.level,
    required this.text,
    required this.choices,
    required this.answer,
    required this.explanation,
    this.passage,
    this.script = const [],
    this.audio,
    this.reviewed = false,
    this.noFurigana = false,
  });

  final String id;
  final Section category;
  final String level;

  /// The question prompt.
  final String text;

  /// Reading passage (読解) shown above the prompt.
  final String? passage;

  /// Listening script (聴解) read aloud with TTS.
  final List<ScriptLine> script;

  /// Optional recorded audio asset. Not played yet (TTS is used in the MVP).
  final String? audio;

  final List<String> choices;
  final int answer;

  /// Language code -> explanation. Always contains at least `en`.
  final Map<String, String> explanation;

  /// True once proofread by a native speaker.
  final bool reviewed;

  /// Never show furigana (e.g. kanji reading questions, where it would
  /// reveal the answer).
  final bool noFurigana;

  String explanationFor(String lang) =>
      explanation[lang] ?? explanation['en'] ?? explanation.values.first;

  factory Question.fromJson(Map<String, dynamic> j) {
    final rawExp = j['explanation'];
    // Backward compatible: older data stored a plain English string.
    final Map<String, String> exp = rawExp is String
        ? {'en': rawExp}
        : (rawExp as Map).map((k, v) => MapEntry(k as String, v as String));
    final choices = (j['choices'] as List).cast<String>();
    final answer = j['answer'] as int;
    if (answer < 0 || answer >= choices.length) {
      throw FormatException('answer out of range in ${j['id']}');
    }
    return Question(
      id: j['id'] as String,
      category: Section.parse(j['category'] as String),
      level: j['level'] as String? ?? 'A2',
      text: j['text'] as String,
      passage: j['passage'] as String?,
      script: ((j['script'] as List?) ?? const [])
          .map((e) => ScriptLine.fromJson(e as Map<String, dynamic>))
          .toList(),
      audio: j['audio'] as String?,
      choices: choices,
      answer: answer,
      explanation: exp,
      reviewed: j['reviewed'] as bool? ?? false,
      noFurigana: j['noFurigana'] as bool? ?? false,
    );
  }

  /// Returns a copy with the choices in random order and [answer] remapped,
  /// so the correct position is uniformly distributed.
  Question shuffled(Random rng) {
    final order = List<int>.generate(choices.length, (i) => i)..shuffle(rng);
    return Question(
      id: id,
      category: category,
      level: level,
      text: text,
      passage: passage,
      script: script,
      audio: audio,
      choices: [for (final i in order) choices[i]],
      answer: order.indexOf(answer),
      explanation: explanation,
      reviewed: reviewed,
      noFurigana: noFurigana,
    );
  }
}
