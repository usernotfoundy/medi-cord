import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

abstract class SpeechService {
  Future<bool> initialize();
  Future<void> startListening({
    required void Function(String text, bool isFinal) onResult,
    void Function(double soundLevel)? onSoundLevel,
  });
  Future<String> stopListening();
  Future<void> cancelListening();
  bool get isListening;
  bool get isAvailable;
}

class SpeechToTextService implements SpeechService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isInitialized = false;
  String _latestWords = '';

  @override
  bool get isListening => _speech.isListening;

  @override
  bool get isAvailable => _isInitialized;

  @override
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      if (!kIsWeb) {
        final status = await Permission.microphone.request();
        if (status.isPermanentlyDenied) {
          debugPrint('Microphone permission permanently denied');
        }
      }

      _isInitialized = await _speech.initialize(
        onError: (errorNotification) {
          debugPrint('Speech recognition error: ${errorNotification.errorMsg}');
        },
        onStatus: (status) {
          debugPrint('Speech recognition status: $status');
        },
      );
    } catch (e) {
      debugPrint('Error initializing speech recognition: $e');
      _isInitialized = false;
    }

    return _isInitialized;
  }

  @override
  Future<void> startListening({
    required void Function(String text, bool isFinal) onResult,
    void Function(double soundLevel)? onSoundLevel,
  }) async {
    if (!_isInitialized) {
      final ok = await initialize();
      if (!ok) {
        throw Exception('Microphone permission or speech recognition unavailable');
      }
    }

    _latestWords = '';

    await _speech.listen(
      onResult: (result) {
        _latestWords = result.recognizedWords;
        onResult(_latestWords, result.finalResult);
      },
      onSoundLevelChange: onSoundLevel,
      listenOptions: stt.SpeechListenOptions(
        listenMode: stt.ListenMode.confirmation,
        cancelOnError: false,
        partialResults: true,
      ),
    );
  }

  @override
  Future<String> stopListening() async {
    if (_speech.isListening) {
      await _speech.stop();
    }
    return _latestWords;
  }

  @override
  Future<void> cancelListening() async {
    if (_speech.isListening) {
      await _speech.cancel();
    }
    _latestWords = '';
  }
}
