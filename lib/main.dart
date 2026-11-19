import 'package:material_ui/material_ui.dart';

import 'app_services.dart';
import 'data/progress_store.dart';
import 'data/question_source.dart';
import 'l10n/app_localizations.dart';
import 'screens/home_screen.dart';
import 'services/purchase_service.dart';
import 'services/tts_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = await ProgressStore.open();
  final purchases = RevenueCatPurchaseService(store);
  // Don't block startup on the network; premium state is cached locally.
  purchases.init();
  runApp(
    JftApp(
      source: const AssetQuestionSource(),
      services: AppServices(
        store: store,
        speaker: TtsSpeaker(),
        purchases: purchases,
      ),
    ),
  );
}

class JftApp extends StatelessWidget {
  const JftApp({
    super.key,
    required this.source,
    required this.services,
    this.includeDrafts,
  });

  final QuestionSource source;
  final AppServices services;
  final bool? includeDrafts;

  static Locale resolveLocale(String? chosen, Locale? system) {
    final code = chosen ?? system?.languageCode;
    return Locale(kSupportedLanguages.containsKey(code) ? code! : 'en');
  }

  @override
  Widget build(BuildContext context) {
    final questions = source.load();
    return ValueListenableBuilder<String?>(
      valueListenable: services.language,
      builder: (context, lang, _) => MaterialApp(
        onGenerateTitle: (ctx) => L10n.of(ctx).appTitle,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorSchemeSeed: const Color(0xFF2E6DB4),
          useMaterial3: true,
        ),
        locale: lang == null ? null : Locale(lang),
        localeResolutionCallback: (system, _) => resolveLocale(lang, system),
        supportedLocales: L10n.supportedLocales,
        // Material + Cupertino + Widgets localizations from material_ui.
        localizationsDelegates: const [
          L10n.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        home: FutureBuilder(
          future: questions,
          builder: (context, snap) {
            if (snap.hasError) {
              return Scaffold(
                body: Center(
                  child: Text('Failed to load questions.\n${snap.error}'),
                ),
              );
            }
            if (!snap.hasData) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            return HomeScreen(
              bank: QuestionBank(snap.data!, includeDrafts: includeDrafts),
              services: services,
            );
          },
        ),
      ),
    );
  }
}
