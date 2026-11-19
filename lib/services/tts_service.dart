import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../logic/ruby.dart';
import '../models/question.dart';

/// Reads listening scripts aloud. Abstract so widget tests can use a fake.
abstract class Speaker {
  /// Returns false if Japanese TTS is unavailable on the device.
  Future<bool> speakScript(List<ScriptLine> lines);
  Future<void> stop();
}

class TtsSpeaker implements Speaker {
  final FlutterTts _tts = FlutterTts();
  bool _ready = false;
  bool _available = true;
  int _generation = 0;

  Future<void> _init() async {
    if (_ready) return;
    _ready = true;
    try {
      final ok = await _tts.isLanguageAvailable('ja-JP');
      _available = ok == true || ok == 1;
      await _tts.setLanguage('ja-JP');
      await _tts.setSpeechRate(0.45); // slower for learners
      await _tts.awaitSpeakCompletion(true);
    } catch (e) {
      debugPrint('TTS init failed: $e');
      _available = false;
    }
  }

  @override
  Future<bool> speakScript(List<ScriptLine> lines) async {
    await _init();
    if (!_available) return false;
    await stop();
    final gen = ++_generation;
    for (final line in lines) {
      if (gen != _generation) break; // stopped or restarted
      // A different pitch per speaker makes dialogues easier to follow.
      await _tts.setPitch(switch (line.speaker) {
        'M' => 0.85,
        'F' => 1.2,
        _ => 1.0,
      });
      // Speak the furigana readings so kanji are pronounced correctly.
      await _tts.speak(readingText(line.text));
      await Future<void>.delayed(const Duration(milliseconds: 350));
    }
    return true;
  }

  @override
  Future<void> stop() async {
    _generation++;
    try {
      await _tts.stop();
    } catch (_) {}
  }
}
