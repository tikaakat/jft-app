import 'dart:math';

import 'package:material_ui/material_ui.dart';

import '../app_services.dart';
import '../config.dart';
import '../l10n/app_localizations.dart';
import '../logic/session.dart';
import '../models/question.dart';
import 'common.dart';
import 'ja_text.dart';
import 'paywall_screen.dart';

enum _After { home, retry, premium }

class QuizScreen extends StatefulWidget {
  const QuizScreen({
    super.key,
    required this.category,
    required this.pool,
    required this.services,
    this.reviewBuilder,
  });

  final Section category;
  final List<Question> pool;
  final AppServices services;

  /// Review mode: builds the question list (e.g. the current mistakes) for
  /// each round. Review rounds don't update the best score or show the paywall.
  final List<Question> Function()? reviewBuilder;

  bool get isReview => reviewBuilder != null;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late List<Question> _questions;
  int _index = 0;
  int? _selected;
  int _correct = 0;
  bool _ttsUnavailable = false;
  final _rng = Random();

  AppServices get s => widget.services;
  bool get _furigana => s.furiganaFor(_q);
  Question get _q => _questions[_index];
  bool get _answered => _selected != null;

  @override
  void initState() {
    super.initState();
    _start();
  }

  void _start() {
    _questions = widget.isReview
        ? [
            for (final q in widget.reviewBuilder!()..shuffle(_rng))
              q.shuffled(_rng),
          ]
        : buildSession(widget.pool, premium: s.isPremium, rng: _rng);
    _index = 0;
    _selected = null;
    _correct = 0;
    s.analytics.log(widget.isReview ? 'review_start' : 'quiz_start', {
      'category': widget.category.name,
      'count': _questions.length,
    });
    _autoPlay();
  }

  void _autoPlay() {
    if (_q.category == Section.listen) _play();
  }

  Future<void> _play() async {
    final ok = await s.speaker.speakScript(_q.script);
    if (!ok && mounted && !_ttsUnavailable) {
      setState(() => _ttsUnavailable = true);
    }
  }

  @override
  void dispose() {
    s.speaker.stop();
    super.dispose();
  }

  Future<void> _choose(int i) async {
    if (_answered) return;
    final ok = i == _q.answer;
    setState(() {
      _selected = i;
      if (ok) _correct++;
    });
    await s.store.recordAnswer(_q, ok);
  }

  Future<void> _next() async {
    await s.speaker.stop();
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
    final t = L10n.of(context);
    final total = _questions.length;
    final newBest =
        !widget.isReview &&
        await s.store.recordSession(widget.category, _correct, total);
    s.analytics.log(widget.isReview ? 'review_complete' : 'quiz_complete', {
      'category': widget.category.name,
      'correct': _correct,
      'total': total,
    });
    final remaining = widget.isReview ? widget.reviewBuilder!().length : 0;
    final locked =
        !widget.isReview &&
        !s.isPremium &&
        widget.pool.length > kFreeLimitPerCategory;
    if (!mounted) return;
    final after = await showDialog<_After>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(t.result),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.scoreCorrect(_correct, total),
              style: Theme.of(ctx).textTheme.headlineSmall,
            ),
            if (newBest) Text(t.newBest),
            if (widget.isReview)
              Text(
                remaining == 0
                    ? t.noMistakesLeft
                    : t.remainingToReview(remaining),
              ),
            if (locked) ...[
              const SizedBox(height: 16),
              Text(t.freeFinished(widget.pool.length)),
            ],
          ],
        ),
        actions: [
          TextButton(
            key: const Key('result_home'),
            onPressed: () => Navigator.pop(ctx, _After.home),
            child: Text(t.home),
          ),
          if (locked)
            FilledButton(
              key: const Key('result_premium'),
              onPressed: () => Navigator.pop(ctx, _After.premium),
              child: Text(t.seePremium),
            )
          else if (!widget.isReview || remaining > 0)
            FilledButton(
              key: const Key('result_retry'),
              onPressed: () => Navigator.pop(ctx, _After.retry),
              child: Text(t.tryAgain),
            ),
        ],
      ),
    );
    if (!mounted) return;
    switch (after) {
      case _After.retry:
        setState(_start);
      case _After.premium:
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => PaywallScreen(services: s, source: 'quiz_end'),
          ),
        );
        if (!mounted) return;
        if (s.isPremium) {
          setState(_start); // continue with the full question set
        } else {
          Navigator.of(context).pop();
        }
      case _After.home || null:
        Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final theme = Theme.of(context);
    final q = _q;
    final label = sectionLabel(t, widget.category);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isReview ? t.reviewTitle(label) : label),
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
            Text(
              t.questionOf(_index + 1, _questions.length),
              style: theme.textTheme.labelLarge,
            ),
            if (!q.reviewed)
              Text(
                t.draftBadge,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            const SizedBox(height: 12),
            if (q.category == Section.listen) _listenControls(t),
            if (q.passage != null) _passage(q.passage!),
            JaText(
              q.text,
              style: theme.textTheme.titleLarge,
              furigana: _furigana,
            ),
            const SizedBox(height: 16),
            for (var i = 0; i < q.choices.length; i++) _choice(i),
            if (_answered) ..._feedback(t),
          ],
        ),
      ),
    );
  }

  Widget _listenControls(L10n t) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FilledButton.tonalIcon(
            key: const Key('play'),
            onPressed: _play,
            icon: const Icon(Icons.volume_up),
            label: Text(t.playAudio),
          ),
          if (_ttsUnavailable)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(t.ttsUnavailable),
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
        child: JaText(
          text,
          style: const TextStyle(fontSize: 17, height: 1.6),
          furigana: _furigana,
        ),
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
        child: JaText(
          _q.choices[i],
          style: TextStyle(fontSize: 18, color: fg),
          furigana: _furigana,
        ),
      ),
    );
  }

  List<Widget> _feedback(L10n t) {
    final theme = Theme.of(context);
    final ok = _selected == _q.answer;
    return [
      const SizedBox(height: 8),
      Text(
        ok ? t.correct : t.incorrect,
        style: theme.textTheme.titleMedium?.copyWith(
          color: ok ? Colors.green.shade700 : theme.colorScheme.error,
        ),
      ),
      const SizedBox(height: 8),
      Text(_q.explanationFor(s.explanationLanguage(context))),
      if (_q.script.isNotEmpty) ...[
        const SizedBox(height: 12),
        Text(t.script, style: theme.textTheme.labelLarge),
        for (final l in _q.script)
          JaText(scriptLineText(l), furigana: _furigana),
      ],
      const SizedBox(height: 16),
      FilledButton(
        key: const Key('next'),
        onPressed: _next,
        child: Text(_index + 1 < _questions.length ? t.next : t.finish),
      ),
    ];
  }
}
