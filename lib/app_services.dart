import 'package:flutter/widgets.dart';

import 'data/progress_store.dart';
import 'models/question.dart';
import 'services/analytics.dart';
import 'services/purchase_service.dart';
import 'services/tts_service.dart';

/// UI languages. Everything except English is LLM-translated and is labelled
/// "includes machine translation" in Settings until a native speaker checks it.
const kSupportedLanguages = <String, String>{
  'en': 'English',
  'id': 'Bahasa Indonesia',
  'ne': 'नेपाली',
  'my': 'မြန်မာ',
  'vi': 'Tiếng Việt',
};

/// Languages whose UI strings have been checked by a native speaker.
const kNativeCheckedLanguages = {'en'};

/// Bundles the app-wide services so screens take a single dependency.
class AppServices {
  AppServices({
    required this.store,
    required this.speaker,
    required this.purchases,
    this.analytics = const Analytics(),
  }) : language = ValueNotifier(store.uiLanguage),
       furigana = ValueNotifier(store.furigana);

  final ProgressStore store;
  final Speaker speaker;
  final PurchaseService purchases;
  final Analytics analytics;

  /// Selected UI language code, or null to follow the system.
  final ValueNotifier<String?> language;

  /// Furigana display preference.
  final ValueNotifier<bool> furigana;

  Future<void> setFurigana(bool v) async {
    furigana.value = v;
    await store.setFurigana(v);
  }

  /// Whether to show furigana for [q].
  bool furiganaFor(Question q) => furigana.value && !q.noFurigana;

  bool get isPremium => purchases.isPremium.value;

  Future<void> setLanguage(String? code) async {
    language.value = code;
    await store.setUiLanguage(code);
  }

  /// Language used for explanations (falls back to English per question).
  String explanationLanguage(BuildContext context) =>
      Localizations.localeOf(context).languageCode;
}
