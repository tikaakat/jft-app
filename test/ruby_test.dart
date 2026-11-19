import 'package:flutter_test/flutter_test.dart';
import 'package:jft_prep/logic/ruby.dart';
import 'package:jft_prep/screens/ja_text.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  const s = '{毎朝|まいあさ}、7{時|じ}に 起きます。';

  test('parse segments', () {
    expect(parseRuby(s), const [
      RubySegment('毎朝', 'まいあさ'),
      RubySegment('、7'),
      RubySegment('時', 'じ'),
      RubySegment('に 起きます。'),
    ]);
  });

  test('plain and reading text', () {
    expect(plainText(s), '毎朝、7時に 起きます。');
    expect(readingText(s), 'まいあさ、7じに 起きます。');
    expect(plainText('no markup'), 'no markup');
  });

  test('validation', () {
    expect(isValidRuby(s), isTrue);
    expect(isValidRuby('{毎朝}'), isFalse);
    expect(isValidRuby('{毎朝|まいあさ'), isFalse);
  });

  Future<void> pump(WidgetTester t, bool furigana) =>
      t.pumpWidget(MaterialApp(home: JaText(s, furigana: furigana)));

  testWidgets('JaText shows readings only when enabled', (t) async {
    await pump(t, false);
    expect(find.text('毎朝、7時に 起きます。'), findsOneWidget);
    expect(find.text('まいあさ'), findsNothing);

    await pump(t, true);
    expect(find.text('まいあさ'), findsOneWidget);
    expect(find.text('毎朝'), findsOneWidget);
  });
}
