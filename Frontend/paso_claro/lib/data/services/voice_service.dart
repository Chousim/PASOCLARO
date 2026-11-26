import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Manages Spanish Text-to-Speech (slow or normal cadence) and Speech-to-Text.
/// Strictly for Spanish — never called on Yucatec Maya or Nahuatl cards.
class VoiceService {
  VoiceService()
      : _tts = FlutterTts(),
        _stt = SpeechToText();

  final FlutterTts _tts;
  final SpeechToText _stt;
  bool _ttsInitialized = false;
  bool _sttAvailable = false;

  Future<void> _ensureTts({required bool slow}) async {
    try {
      if (!_ttsInitialized) {
        await _tts.setLanguage('es-MX');
        _ttsInitialized = true;
      }
      await _tts.setSpeechRate(slow ? 0.38 : 0.5);
      await _tts.setPitch(1.0);
    } catch (_) {
      // Gracefully ignore in test/headless environments without platform channel.
    }
  }

  Future<void> speakSpanish(String text, {required bool slow}) async {
    try {
      await _ensureTts(slow: slow);
      await _tts.stop();
      await _tts.speak(text);
    } catch (_) {}
  }

  Future<void> stopSpeaking() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }

  Future<bool> startListening({
    required void Function(String recognizedText) onResult,
    required void Function() onDone,
  }) async {
    try {
      if (!_sttAvailable) {
        _sttAvailable = await _stt.initialize(
          onStatus: (status) {
            if (status == 'done' || status == 'notListening') {
              onDone();
            }
          },
        );
      }
      if (!_sttAvailable) return false;
      await _stt.listen(
        localeId: 'es_MX',
        listenOptions: SpeechListenOptions(
          cancelOnError: true,
          partialResults: true,
        ),
        onResult: (result) {
          if (result.recognizedWords.isNotEmpty) {
            onResult(result.recognizedWords);
          }
          if (result.finalResult) {
            onDone();
          }
        },
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> stopListening() async {
    try {
      await _stt.stop();
    } catch (_) {}
  }
}
