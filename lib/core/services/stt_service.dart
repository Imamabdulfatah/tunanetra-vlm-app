import 'dart:async';

import 'package:speech_to_text/speech_to_text.dart' as stt;

class SttService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool isListening = false;
  String lastResult = "";

  Future<bool> init() async {
    bool available = await _speech.initialize(
      onStatus: (status) => print('🎤 STATUS: $status'),
      onError: (error) => print('❌ ERROR: $error'),
    );
    if (available) {
      print("✅ Speech to Text siap digunakan");
    } else {
      print("❌ Speech to Text tidak tersedia");
    }
    return available;
  }

  Future<String?> listen({int timeoutSeconds = 15}) async {
    if (isListening) return null;

    Completer<String?> completer = Completer();
    isListening = true;
    lastResult = "";

    await _speech.listen(
      localeId: 'id_ID',
      onResult: (result) {
        if (result.finalResult) {
          lastResult = result.recognizedWords.trim();
          if (lastResult.isNotEmpty) {
            completer.complete(lastResult);
          } else {
            completer.complete(null);
          }
        }
      },
      onSoundLevelChange: (level) => print("Sound level: $level"),
      cancelOnError: true,
      partialResults: false,
    );

    return completer.future.timeout(
      Duration(seconds: timeoutSeconds),
      onTimeout: () {
        print("Speech-to-text timeout");
        return null; // Return null on timeout
      },
    ).whenComplete(() {
      stop();
    });
  }

  Future<void> stop() async {
    await _speech.stop();
    isListening = false;
  }
}
