import 'package:material_ui/material_ui.dart';

import '../app_services.dart';
import '../data/progress_store.dart';
import '../data/question_source.dart';
import '../l10n/app_localizations.dart';
import '../models/question.dart';
import 'common.dart';
import 'ja_text.dart';
import 'quiz_screen.dart';

/// Current mistakes of [c] that still exist in the bank, in bank order.
List<Question> mistakesOf(QuestionBank bank, ProgressStore store, Section c) {
  final wrong = store.wrong(c);
  return bank.of(c).where((q) => wrong.contains(q.id)).toList();
}

/// Lists questions whose latest answer was wrong, per section, and lets the
/// learner retry them. A question leaves the list once answered correctly.
class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key, required this.bank, required this.services});

  final QuestionBank bank;
  final AppServices services;

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  AppServices get s => widget.services;

  Future<void> _retry(Section c) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => QuizScreen(
          category: c,
          pool: widget.bank.of(c),
          services: s,
          reviewBuilder: () => mistakesOf(widget.bank, s.store, c),
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  void _showDetail(L10n t, Question q) {
    final f = s.furiganaFor(q);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (q.passage != null) ...[
                JaText(q.passage!, furigana: f),
                const Divider(),
              ],
              if (q.script.isNotEmpty) ...[
                for (final l in q.script)
                  JaText(scriptLineText(l), furigana: f),
                const Divider(),
              ],
              JaText(
                q.text,
                style: Theme.of(ctx).textTheme.titleMedium,
                furigana: f,
              ),
              const SizedBox(height: 8),
              Text(
                t.answerIs(plain(q.choices[q.answer])),
                style: TextStyle(
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(q.explanationFor(s.explanationLanguage(ctx))),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t.close)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final groups = {
      for (final c in Section.values) c: mistakesOf(widget.bank, s.store, c),
    }..removeWhere((_, v) => v.isEmpty);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(t.reviewMistakes)),
      body: groups.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(t.noMistakes, textAlign: TextAlign.center),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final e in groups.entries) ...[
                  Row(
                    children: [
                      Icon(
                        sectionIcon(e.key),
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${sectionLabel(t, e.key)} (${e.value.length})',
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                      FilledButton.tonal(
                        key: Key('review_${e.key.name}'),
                        onPressed: () => _retry(e.key),
                        child: Text(t.retry),
                      ),
                    ],
                  ),
                  for (final q in e.value)
                    ListTile(
                      dense: true,
                      title: Text(
                        plain(q.text).split('\n').first,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: const Icon(Icons.info_outline),
                      onTap: () => _showDetail(t, q),
                    ),
                  const Divider(),
                ],
              ],
            ),
    );
  }
}
