import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:jft_prep/app_services.dart';

/// Every supported language must define every key with the same placeholders.
void main() {
  Map<String, dynamic> arb(String lang) =>
      jsonDecode(File('lib/l10n/app_$lang.arb').readAsStringSync())
          as Map<String, dynamic>;
  Set<String> keys(Map<String, dynamic> m) =>
      m.keys.where((k) => !k.startsWith('@')).toSet();
  Set<String> placeholders(String s) =>
      RegExp(r'\{(\w+)\}').allMatches(s).map((m) => m[1]!).toSet();

  final en = arb('en');
  for (final lang in kSupportedLanguages.keys.where((l) => l != 'en')) {
    test('$lang has all keys and placeholders', () {
      final other = arb(lang);
      expect(keys(other), keys(en));
      for (final k in keys(en)) {
        expect(
          placeholders(other[k] as String),
          placeholders(en[k] as String),
          reason: '$lang.$k',
        );
      }
    });
  }
}
