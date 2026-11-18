import 'package:material_ui/material_ui.dart';

import '../config.dart';
import '../data/progress_store.dart';
import '../logic/session.dart';
import '../models/question.dart';
import '../services/analytics.dart';
import '../services/tts_service.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({
    super.key,
    required this.category,
    required this.pool,
    required this.store,
    required this.speaker,
    required this.analytics,
  });

  final Section category;
  final List<Question> pool;
  final ProgressStore store;
  final Speaker speaker;
  final Analytics analytics;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late List<Question> _questions;
  int _index = 0;
  int? _selected;
  int _correct = 0;
  bool _ttsUnavailable = false;

  Question get _q => _questions[_index];
  bool get _answered => _selected != null;

  @override
  void initState() {
    super.initState();
    _start();
  }

  void _start() {
    _questions = buildSession(widget.pool, premium: widget.store.isPremium);
    _index = 0;
    _selected = null;
    _correct = 0;
    widget.analytics.log('quiz_start', {
      'category': widget.category.name,
      'count': _questions.length,
    });
    _autoPlay();
  }

  void _autoPlay() {
    if (_q.category == Section.listen) _play();
  }

  Future<void> _play() async {
    final ok = await widget.speaker.speakScript(_q.script);
    if (!ok && mounted && !_ttsUnavailable) {
      setState(() => _ttsUnavailable = true);
    }
  }

  @override
  void dispose() {
    widget.speaker.stop();
    super.dispose();
  }

  Future<void> _choose(int i) async {
    if (_answered) return;
    final ok = i == _q.answer;
    setState(() {
      _selected = i;
      if (ok) _correct++;
    });
    await widget.store.recordAnswer(_q, ok);
  }

  Future<void> _next() async {
    await widget.speaker.stop();
    if (_index + 1 < _questions.length) {
      setState(() {
        _index++;
        _selected = null;
      });
      _autoPlay();
    } else {
      await _finish();
    }
  }

  Future<void> _finish() async {
    final total = _questions.length;
    final newBest =
        await widget.store.recordSession(widget.category, _correct, total);
    widget.analytics.log('quiz_complete', {
      'category': widget.category.name,
      'correct': _correct,
      'total': total,
    });
    final locked = !widget.store.isPremium &&
        widget.pool.length > kFreeLimitPerCategory;
    if (locked) {
      widget.analytics.log('paywall_view', {'category': widget.category.name});
    }
    if (!mounted) return;
    final again = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Result'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$_correct / $total correct',
                style: Theme.of(ctx).textTheme.headlineSmall),
            if (newBest) const Text('New best score!'),
            if (locked) ...[
              const SizedBox(height: 16),
              Text(
                'You have finished the free questions. Premium (coming soon) '
                'unlocks all ${widget.pool.length} questions in this section.',
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            key: const Key('result_home'),
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Home'),
          ),
          FilledButton(
            key: const Key('result_retry'),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Try again'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (again == true) {
      setState(_start);
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final q = _q;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category.label),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_index + (_answered ? 1 : 0)) / _questions.length,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Question ${_index + 1} / ${_questions.length}',
                style: theme.textTheme.labelLarge),
            if (!q.reviewed)
              Text('DRAFT (not yet proofread)',
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: theme.colorScheme.error)),
            const SizedBox(height: 12),
            if (q.category == Section.listen) _listenControls(),
            if (q.passage != null) _passage(q.passage!),
            Text(q.text, style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            for (var i = 0; i < q.choices.length; i++) _choice(i),
            if (_answered) ..._feedback(),
          ],
        ),
      ),
    );
  }

  Widget _listenControls() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FilledButton.tonalIcon(
            key: const Key('play'),
            onPressed: _play,
            icon: const Icon(Icons.volume_up),
            label: const Text('Play audio'),
          ),
          if (_ttsUnavailable)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Japanese voice is not available. Install it in Android '
                'Settings > Text-to-speech output (Google Speech Services).',
              ),
            ),
        ],
      ),
    );
  }

  Widget _passage(String text) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(text, style: const TextStyle(fontSize: 17, height: 1.6)),
      ),
    );
  }

  Widget _choice(int i) {
    final scheme = Theme.of(context).colorScheme;
    Color? bg;
    Color? fg;
    if (_answered) {
      if (i == _q.answer) {
        bg = Colors.green.shade600;
        fg = Colors.white;
      } else if (i == _selected) {
        bg = scheme.error;
        fg = scheme.onError;
      }
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: OutlinedButton(
        key: Key('choice_$i'),
        style: OutlinedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          disabledForegroundColor: fg,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          alignment: Alignment.centerLeft,
        ),
        onPressed: _answered ? null : () => _choose(i),
        child: Text(_q.choices[i], style: const TextStyle(fontSize: 18)),
      ),
    );
  }

  List<Widget> _feedback() {
    final theme = Theme.of(context);
    final ok = _selected == _q.answer;
    return [
      const SizedBox(height: 8),
      Text(ok ? 'Correct!' : 'Incorrect',
          style: theme.textTheme.titleMedium?.copyWith(
              color: ok ? Colors.green.shade700 : theme.colorScheme.error)),
      const SizedBox(height: 8),
      Text(_q.explanationFor('en')),
      if (_q.script.isNotEmpty) ...[
        const SizedBox(height: 12),
        Text('Script', style: theme.textTheme.labelLarge),
        for (final l in _q.script)
          Text('${l.speaker == 'N' ? '' : '${l.speaker}: '}${l.text}'),
      ],
      const SizedBox(height: 16),
      FilledButton(
        key: const Key('next'),
        onPressed: _next,
        child: Text(_index + 1 < _questions.length ? 'Next' : 'Finish'),
      ),
    ];
  }
}
