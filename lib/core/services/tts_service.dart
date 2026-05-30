import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _tts = FlutterTts();
  bool isSpeaking = false;

  Future<void> init() async {
    await _tts.setLanguage("id-ID");
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);

    _tts.setStartHandler(() {
      isSpeaking = true;
      print("TTS started speaking");
    });

    _tts.setCompletionHandler(() {
      isSpeaking = false;
      print("TTS finished speaking");
    });

    _tts.setErrorHandler((msg) {
      isSpeaking = false;
      print("TTS error: $msg");
    });
  }

  Future<void> speak(String text) async {
    await _tts.stop();
    isSpeaking = false;
    await _tts.setSpeechRate(0.5);
    await _tts.setPitch(1.0);
    await _tts.speak(text);
  }

  Future<void> speakDino(String text) async {
    await _tts.stop();
    isSpeaking = false;
    await _tts.setSpeechRate(0.7);
    await _tts.setPitch(0.8);
    await _tts.speak(text);
  }

  Future<void> stop() async {
    await _tts.stop();
    isSpeaking = false;
  }
}
