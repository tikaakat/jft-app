/// Furigana markup: `{漢字|かんじ}`. Text outside braces is plain.
library;

class RubySegment {
  const RubySegment(this.base, [this.ruby]);
  final String base;
  final String? ruby;

  @override
  bool operator ==(Object other) =>
      other is RubySegment && other.base == base && other.ruby == ruby;
  @override
  int get hashCode => Object.hash(base, ruby);
  @override
  String toString() => ruby == null ? base : '{$base|$ruby}';
}

final _ruby = RegExp(r'\{([^{}|]+)\|([^{}|]+)\}');

List<RubySegment> parseRuby(String s) {
  final out = <RubySegment>[];
  var pos = 0;
  for (final m in _ruby.allMatches(s)) {
    if (m.start > pos) out.add(RubySegment(s.substring(pos, m.start)));
    out.add(RubySegment(m[1]!, m[2]!));
    pos = m.end;
  }
  if (pos < s.length) out.add(RubySegment(s.substring(pos)));
  return out;
}

/// Text as written, without readings: `{毎朝|まいあさ}` -> `毎朝`.
String plainText(String s) => s.replaceAllMapped(_ruby, (m) => m[1]!);

/// Text with kanji replaced by their readings (used for TTS accuracy).
String readingText(String s) => s.replaceAllMapped(_ruby, (m) => m[2]!);

/// True if braces are balanced and every `{...}` is a valid `{base|ruby}`.
bool isValidRuby(String s) =>
    !s.replaceAll(_ruby, '').contains(RegExp(r'[{}]'));
