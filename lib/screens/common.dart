import 'package:material_ui/material_ui.dart';

import '../l10n/app_localizations.dart';
import '../logic/ruby.dart';
import '../models/question.dart';

IconData sectionIcon(Section c) => switch (c) {
  Section.vocab => Icons.translate,
  Section.conv => Icons.forum_outlined,
  Section.listen => Icons.headphones,
  Section.read => Icons.menu_book_outlined,
};

String sectionLabel(L10n t, Section c) => switch (c) {
  Section.vocab => t.sectionVocab,
  Section.conv => t.sectionConv,
  Section.listen => t.sectionListen,
  Section.read => t.sectionRead,
};

/// Script line with speaker prefix. Keeps furigana markup for [JaText].
String scriptLineText(ScriptLine l) =>
    l.speaker == 'N' ? l.text : '${l.speaker}: ${l.text}';

String plain(String s) => plainText(s);
