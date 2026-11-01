import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/parsing/vital_parser.dart';
import '../../data/db/app_database.dart';
import '../../data/models/vital_reading.dart';
import '../../data/repositories/vital_repository.dart';
import '../../speech/speech_service.dart';

enum RecordStatus {
  idle,
  listening,
  processing,
  review,
  error,
}

class RecordState {
  final RecordStatus status;
  final String rawTranscript;
  final ParsedReading? parsedReading;
  final String? errorMessage;
  final double soundLevel;

  const RecordState({
    this.status = RecordStatus.idle,
    this.rawTranscript = '',
    this.parsedReading,
    this.errorMessage,
    this.soundLevel = 0.0,
  });

  RecordState copyWith({
    RecordStatus? status,
    String? rawTranscript,
    ParsedReading? parsedReading,
    String? errorMessage,
    double? soundLevel,
  }) {
    return RecordState(
      status: status ?? this.status,
      rawTranscript: rawTranscript ?? this.rawTranscript,
      parsedReading: parsedReading ?? this.parsedReading,
      errorMessage: errorMessage ?? this.errorMessage,
      soundLevel: soundLevel ?? this.soundLevel,
    );
  }
}

// Providers
final speechServiceProvider = Provider<SpeechService>((ref) {
  return SpeechToTextService();
});

final vitalRepositoryProvider = Provider<VitalRepository>((ref) {
  return VitalRepository();
});

final readingsListProvider = FutureProvider<List<VitalReading>>((ref) async {
  AppDatabase.ensureInitialized();
  final repo = ref.watch(vitalRepositoryProvider);
  return await repo.getAllReadings();
});

final recordControllerProvider =
    NotifierProvider<RecordController, RecordState>(RecordController.new);

class RecordController extends Notifier<RecordState> {
  late final SpeechService _speech;
  late final VitalRepository _repo;

  @override
  RecordState build() {
    _speech = ref.watch(speechServiceProvider);
    _repo = ref.watch(vitalRepositoryProvider);
    return const RecordState();
  }

  /// Called when user presses and holds the mic button
  Future<void> onMicPressDown() async {
    try {
      state = state.copyWith(
        status: RecordStatus.listening,
        rawTranscript: '',
        parsedReading: null,
        errorMessage: null,
        soundLevel: 0.0,
      );

      final initialized = await _speech.initialize();
      if (!initialized) {
        state = state.copyWith(
          status: RecordStatus.error,
          errorMessage:
              'Could not access microphone or speech engine. Please check permissions.',
        );
        return;
      }

      await _speech.startListening(
        onResult: (text, isFinal) {
          final trimmed = text.trim();
          if (trimmed.isEmpty) return;

          state = state.copyWith(
            rawTranscript: text,
          );

          // Late-arriving result recovery:
          // If the mic was already released (status is processing or error),
          // automatically attempt to parse this updated complete transcript.
          if (state.status == RecordStatus.processing ||
              state.status == RecordStatus.error) {
            final parseResult = VitalParser.parse(trimmed);
            if (parseResult is ParseSuccess) {
              state = state.copyWith(
                status: RecordStatus.review,
                rawTranscript: trimmed,
                parsedReading: parseResult.reading,
                errorMessage: null,
              );
            }
          }
        },
        onSoundLevel: (level) {
          if (state.status == RecordStatus.listening) {
            state = state.copyWith(soundLevel: level);
          }
        },
      );
    } catch (e) {
      state = state.copyWith(
        status: RecordStatus.error,
        errorMessage: 'Microphone error: $e',
      );
    }
  }

  /// Called when user releases the mic button
  Future<void> onMicPressUp() async {
    if (state.status != RecordStatus.listening) return;

    state = state.copyWith(status: RecordStatus.processing);

    try {
      final finalText = await _speech.stopListening();

      // Step 1: Buffer flush grace period.
      // Give the native speech recognizer 350ms to finish emitting the trailing syllables
      // spoken right before finger release.
      await Future.delayed(const Duration(milliseconds: 350));

      // If a late-arriving onResult callback already parsed and transitioned to review, we're done.
      if (state.status == RecordStatus.review) {
        return;
      }

      // Pick the most complete transcript available
      final transcriptToParse = state.rawTranscript.length >= finalText.length
          ? state.rawTranscript
          : finalText;

      _processTranscript(transcriptToParse);
    } catch (e) {
      state = state.copyWith(
        status: RecordStatus.error,
        errorMessage: 'Failed to process voice recording: $e',
      );
    }
  }

  /// Manually simulates or feeds text (useful for demo & simulator testing)
  void simulateSpeechInput(String text) {
    state = state.copyWith(status: RecordStatus.processing, rawTranscript: text);
    _processTranscript(text);
  }

  void _processTranscript(String transcript) {
    if (transcript.trim().isEmpty) {
      state = state.copyWith(
        status: RecordStatus.error,
        rawTranscript: '',
        errorMessage:
            'No speech detected. Please press and hold the mic while speaking clearly.',
      );
      return;
    }

    final parseResult = VitalParser.parse(transcript);

    switch (parseResult) {
      case ParseSuccess(:final reading):
        state = state.copyWith(
          status: RecordStatus.review,
          rawTranscript: transcript,
          parsedReading: reading,
          errorMessage: null,
        );
      case ParseFailure(:final message, :final rawTranscript):
        state = state.copyWith(
          status: RecordStatus.error,
          rawTranscript: rawTranscript,
          errorMessage: message,
        );
    }
  }

  /// Retry: discards current recording and returns to idle
  void retry() {
    _speech.cancelListening();
    state = const RecordState(status: RecordStatus.idle);
  }

  /// Save: commits parsed reading to local SQLite database
  Future<bool> saveReading() async {
    final parsed = state.parsedReading;
    if (parsed == null) return false;

    try {
      final reading = VitalReading(
        type: parsed.vitalType,
        valuePrimary: parsed.primaryValue,
        valueSecondary: parsed.secondaryValue,
        valueTertiary: parsed.tertiaryValue,
        unit: parsed.unit,
        rawTranscript: parsed.rawTranscript,
        recordedAt: DateTime.now(),
        note: parsed.warningMessage,
      );

      await _repo.insertReading(reading);

      // Refresh list provider
      ref.invalidate(readingsListProvider);

      state = const RecordState(status: RecordStatus.idle);
      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to save to database: $e',
      );
      return false;
    }
  }

  /// Updates parsed reading before saving if the user edits the value
  void updateParsedReading(ParsedReading updated) {
    state = state.copyWith(parsedReading: updated);
  }
}
