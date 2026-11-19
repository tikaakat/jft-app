import 'package:material_ui/material_ui.dart';

import '../logic/ruby.dart';

/// Japanese text that understands `{漢字|かんじ}` furigana markup.
/// With [furigana] off (or no markup) it renders as plain text.
class JaText extends StatelessWidget {
  const JaText(this.text, {super.key, this.style, this.furigana = false});

  final String text;
  final TextStyle? style;
  final bool furigana;

  @override
  Widget build(BuildContext context) {
    final segments = parseRuby(text);
    final hasRuby = segments.any((s) => s.ruby != null);
    if (!furigana || !hasRuby) return Text(plainText(text), style: style);

    final base = DefaultTextStyle.of(context).style.merge(style);
    final size = base.fontSize ?? 14;
    final rubyStyle = base.copyWith(fontSize: size * 0.5, height: 1.0);
    return Text.rich(
      TextSpan(
        children: [
          for (final s in segments)
            if (s.ruby == null)
              TextSpan(text: s.base)
            else
              WidgetSpan(
                alignment: PlaceholderAlignment.bottom,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(s.ruby!, style: rubyStyle),
                    Text(s.base, style: base.copyWith(height: 1.0)),
                  ],
                ),
              ),
        ],
      ),
      // Leave room above every line for the readings.
      style: base.copyWith(height: 2.0),
    );
  }
}
