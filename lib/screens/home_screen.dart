import 'package:material_ui/material_ui.dart';

import '../config.dart';
import '../data/progress_store.dart';
import '../data/question_source.dart';
import '../models/question.dart';
import '../services/analytics.dart';
import '../services/tts_service.dart';
import 'quiz_screen.dart';
import 'review_screen.dart';

IconData categoryIcon(Section c) => switch (c) {
      Section.vocab => Icons.translate,
      Section.conv => Icons.forum_outlined,
      Section.listen => Icons.headphones,
      Section.read => Icons.menu_book_outlined,
    };

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.bank,
    required this.store,
    required this.speaker,
    required this.analytics,
  });

  final QuestionBank bank;
  final ProgressStore store;
  final Speaker speaker;
  final Analytics analytics;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<void> _open(Section c) async {
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => QuizScreen(
        category: c,
        pool: widget.bank.of(c),
        store: widget.store,
        speaker: widget.speaker,
        analytics: widget.analytics,
      ),
    ));
    if (mounted) setState(() {}); // refresh scores
  }

  Future<void> _openReview() async {
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => ReviewScreen(
        bank: widget.bank,
        store: widget.store,
        speaker: widget.speaker,
        analytics: widget.analytics,
      ),
    ));
    if (mounted) setState(() {});
  }

  int _mistakeCount() => Section.values
      .map((c) => mistakesOf(widget.bank, widget.store, c).length)
      .fold(0, (a, b) => a + b);

  Widget _summary() {
    final theme = Theme.of(context);
    var total = 0, mastered = 0, answered = 0, correct = 0;
    for (final c in Section.values) {
      final ids = widget.bank.of(c).map((q) => q.id).toSet();
      total += ids.length;
      mastered += widget.store.mastered(c).intersection(ids).length;
      answered += widget.store.answeredCount(c);
      correct += widget.store.correctCount(c);
    }
    final acc = answered == 0 ? '–' : '${(correct * 100 / answered).round()}%';
    Widget stat(String value, String label) => Expanded(
          child: Column(children: [
            Text(value, style: theme.textTheme.titleLarge),
            Text(label, style: theme.textTheme.bodySmall),
          ]),
        );
    return Card(
      key: const Key('summary'),
      color: theme.colorScheme.primaryContainer,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Row(children: [
          stat('$mastered / $total', 'Mastered'),
          stat('$answered', 'Answered'),
          stat(acc, 'Accuracy'),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final premium = widget.store.isPremium;
    final mistakes = _mistakeCount();
    return Scaffold(
      appBar: AppBar(
        title: const Text('JFT-Basic Prep'),
        actions: [
          IconButton(
            key: const Key('open_review'),
            tooltip: 'Review mistakes',
            onPressed: _openReview,
            icon: Badge(
              isLabelVisible: mistakes > 0,
              label: Text('$mistakes'),
              child: const Icon(Icons.replay),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _summary(),
          Text(
            premium
                ? 'Premium: all questions unlocked'
                : 'Free: $kFreeLimitPerCategory questions per section',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          for (final c in Section.values) _card(c),
        ],
      ),
    );
  }

  Widget _card(Section c) {
    final pool = widget.bank.of(c);
    final best = widget.store.bestPercent(c);
    final ids = pool.map((q) => q.id).toSet();
    final done = widget.store.mastered(c).intersection(ids).length;
    final drafts = pool.where((q) => !q.reviewed).length;
    final answered = widget.store.answeredCount(c);
    final acc = answered == 0
        ? null
        : (widget.store.correctCount(c) * 100 / answered).round();
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        key: Key('card_${c.name}'),
        borderRadius: BorderRadius.circular(12),
        onTap: pool.isEmpty ? null : () => _open(c),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(categoryIcon(c), size: 36, color: theme.colorScheme.primary),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.label, style: theme.textTheme.titleMedium),
                    Text(c.labelJa, style: theme.textTheme.bodySmall),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: pool.isEmpty ? 0 : done / pool.length,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        'Mastered $done / ${pool.length}',
                        best < 0 ? 'Best: –' : 'Best: $best%',
                        if (acc != null) 'Accuracy: $acc%',
                        if (drafts > 0) 'Drafts: $drafts',
                      ].join('   ·   '),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
