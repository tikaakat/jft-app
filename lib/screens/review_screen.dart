import 'package:material_ui/material_ui.dart';

import '../data/progress_store.dart';
import '../data/question_source.dart';
import '../models/question.dart';
import '../services/analytics.dart';
import '../services/tts_service.dart';
import 'home_screen.dart' show categoryIcon;
import 'quiz_screen.dart';

/// Lists questions whose latest answer was wrong, per section, and lets the
/// learner retry them. A question leaves the list once answered correctly.
class ReviewScreen extends StatefulWidget {
  const ReviewScreen({
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
  State<ReviewScreen> createState() => _ReviewScreenState();
}

/// Current mistakes of [c] that still exist in the bank, in bank order.
List<Question> mistakesOf(QuestionBank bank, ProgressStore store, Section c) {
  final wrong = store.wrong(c);
  return bank.of(c).where((q) => wrong.contains(q.id)).toList();
}

class _ReviewScreenState extends State<ReviewScreen> {
  Future<void> _retry(Section c) async {
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => QuizScreen(
        category: c,
        pool: widget.bank.of(c),
        store: widget.store,
        speaker: widget.speaker,
        analytics: widget.analytics,
        reviewBuilder: () => mistakesOf(widget.bank, widget.store, c),
      ),
    ));
    if (mounted) setState(() {});
  }

  void _showDetail(Question q) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (q.passage != null) ...[Text(q.passage!), const Divider()],
              if (q.script.isNotEmpty) ...[
                for (final l in q.script)
                  Text('${l.speaker == 'N' ? '' : '${l.speaker}: '}${l.text}'),
                const Divider(),
              ],
              Text(q.text, style: Theme.of(ctx).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text('Answer: ${q.choices[q.answer]}',
                  style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(q.explanationFor('en')),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final groups = {
      for (final c in Section.values)
        c: mistakesOf(widget.bank, widget.store, c),
    }..removeWhere((_, v) => v.isEmpty);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Review mistakes')),
      body: groups.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('No mistakes to review.\nKeep practicing!',
                    textAlign: TextAlign.center),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final e in groups.entries) ...[
                  Row(
                    children: [
                      Icon(categoryIcon(e.key),
                          color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text('${e.key.label} (${e.value.length})',
                            style: theme.textTheme.titleMedium),
                      ),
                      FilledButton.tonal(
                        key: Key('review_${e.key.name}'),
                        onPressed: () => _retry(e.key),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                  for (final q in e.value)
                    ListTile(
                      dense: true,
                      title: Text(q.text.split('\n').first,
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                      trailing: const Icon(Icons.info_outline),
                      onTap: () => _showDetail(q),
                    ),
                  const Divider(),
                ],
              ],
            ),
    );
  }
}
