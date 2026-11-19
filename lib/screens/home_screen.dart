import 'package:material_ui/material_ui.dart';

import '../app_services.dart';
import '../config.dart';
import '../data/question_source.dart';
import '../l10n/app_localizations.dart';
import '../models/question.dart';
import 'common.dart';
import 'paywall_screen.dart';
import 'quiz_screen.dart';
import 'review_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.bank, required this.services});

  final QuestionBank bank;
  final AppServices services;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  AppServices get s => widget.services;

  Future<void> _push(Widget screen) async {
    await Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => screen));
    if (mounted) setState(() {}); // refresh scores
  }

  int _mistakeCount() => Section.values
      .map((c) => mistakesOf(widget.bank, s.store, c).length)
      .fold(0, (a, b) => a + b);

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final mistakes = _mistakeCount();
    return Scaffold(
      appBar: AppBar(
        title: Text(t.appTitle),
        actions: [
          IconButton(
            key: const Key('open_review'),
            tooltip: t.reviewMistakes,
            onPressed: () =>
                _push(ReviewScreen(bank: widget.bank, services: s)),
            icon: Badge(
              isLabelVisible: mistakes > 0,
              label: Text('$mistakes'),
              child: const Icon(Icons.replay),
            ),
          ),
          IconButton(
            key: const Key('open_settings'),
            tooltip: t.settings,
            onPressed: () => _push(SettingsScreen(services: s)),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: ValueListenableBuilder<bool>(
        valueListenable: s.purchases.isPremium,
        builder: (context, premium, _) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _summary(t),
            if (premium)
              Text(t.premiumUnlocked)
            else
              Row(
                children: [
                  Expanded(child: Text(t.freeLimit(kFreeLimitPerCategory))),
                  TextButton(
                    key: const Key('home_unlock'),
                    onPressed: () =>
                        _push(PaywallScreen(services: s, source: 'home')),
                    child: Text(t.unlockAll),
                  ),
                ],
              ),
            const SizedBox(height: 12),
            for (final c in Section.values) _card(t, c),
          ],
        ),
      ),
    );
  }

  Widget _summary(L10n t) {
    final theme = Theme.of(context);
    var total = 0, mastered = 0, answered = 0, correct = 0;
    for (final c in Section.values) {
      final ids = widget.bank.of(c).map((q) => q.id).toSet();
      total += ids.length;
      mastered += s.store.mastered(c).intersection(ids).length;
      answered += s.store.answeredCount(c);
      correct += s.store.correctCount(c);
    }
    final acc = answered == 0 ? '–' : '${(correct * 100 / answered).round()}%';
    Widget stat(String value, String label) => Expanded(
      child: Column(
        children: [
          Text(value, style: theme.textTheme.titleLarge),
          Text(
            label,
            style: theme.textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
    return Card(
      key: const Key('summary'),
      color: theme.colorScheme.primaryContainer,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Row(
          children: [
            stat('$mastered / $total', t.statMastered),
            stat('$answered', t.statAnswered),
            stat(acc, t.statAccuracy),
          ],
        ),
      ),
    );
  }

  Widget _card(L10n t, Section c) {
    final pool = widget.bank.of(c);
    final best = s.store.bestPercent(c);
    final ids = pool.map((q) => q.id).toSet();
    final done = s.store.mastered(c).intersection(ids).length;
    final drafts = pool.where((q) => !q.reviewed).length;
    final answered = s.store.answeredCount(c);
    final acc = answered == 0
        ? null
        : (s.store.correctCount(c) * 100 / answered).round();
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        key: Key('card_${c.name}'),
        borderRadius: BorderRadius.circular(12),
        onTap: pool.isEmpty
            ? null
            : () => _push(QuizScreen(category: c, pool: pool, services: s)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(sectionIcon(c), size: 36, color: theme.colorScheme.primary),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sectionLabel(t, c),
                      style: theme.textTheme.titleMedium,
                    ),
                    Text(c.labelJa, style: theme.textTheme.bodySmall),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: pool.isEmpty ? 0 : done / pool.length,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        t.masteredOf(done, pool.length),
                        best < 0 ? t.bestNone : t.bestScore(best),
                        if (acc != null) t.accuracyValue(acc),
                        if (drafts > 0) t.draftsCount(drafts),
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
