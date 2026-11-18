import 'package:material_ui/material_ui.dart';

import 'config.dart';
import 'data/progress_store.dart';
import 'data/question_source.dart';
import 'screens/home_screen.dart';
import 'services/analytics.dart';
import 'services/tts_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = await ProgressStore.open();
  if (kUnlockAll) await store.setPremium(true);
  runApp(JftApp(
    source: const AssetQuestionSource(),
    store: store,
    speaker: TtsSpeaker(),
  ));
}

class JftApp extends StatelessWidget {
  const JftApp({
    super.key,
    required this.source,
    required this.store,
    required this.speaker,
    this.analytics = const Analytics(),
    this.includeDrafts,
  });

  final QuestionSource source;
  final ProgressStore store;
  final Speaker speaker;
  final Analytics analytics;
  final bool? includeDrafts;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JFT-Basic Prep',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF2E6DB4),
        useMaterial3: true,
      ),
      home: FutureBuilder(
        future: source.load(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Scaffold(
              body: Center(child: Text('Failed to load questions.\n${snap.error}')),
            );
          }
          if (!snap.hasData) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          return HomeScreen(
            bank: QuestionBank(snap.data!, includeDrafts: includeDrafts),
            store: store,
            speaker: speaker,
            analytics: analytics,
          );
        },
      ),
    );
  }
}
