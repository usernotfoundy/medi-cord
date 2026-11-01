import 'package:flutter/foundation.dart';
import '../vitals/vital_type.dart';
import 'number_words.dart';

@immutable
class ParsedReading {
  final VitalType vitalType;
  final double primaryValue;
  final double? secondaryValue;
  final double? tertiaryValue;
  final String unit;
  final String rawTranscript;
  final String? warningMessage;

  const ParsedReading({
    required this.vitalType,
    required this.primaryValue,
    this.secondaryValue,
    this.tertiaryValue,
    required this.unit,
    required this.rawTranscript,
    this.warningMessage,
  });

  String get formattedValue =>
      vitalType.formatValue(primaryValue, secondaryValue, tertiaryValue);

  ParsedReading copyWith({
    VitalType? vitalType,
    double? primaryValue,
    double? secondaryValue,
    double? tertiaryValue,
    String? unit,
    String? rawTranscript,
    String? warningMessage,
  }) {
    return ParsedReading(
      vitalType: vitalType ?? this.vitalType,
      primaryValue: primaryValue ?? this.primaryValue,
      secondaryValue: secondaryValue ?? this.secondaryValue,
      tertiaryValue: tertiaryValue ?? this.tertiaryValue,
      unit: unit ?? this.unit,
      rawTranscript: rawTranscript ?? this.rawTranscript,
      warningMessage: warningMessage ?? this.warningMessage,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ParsedReading &&
          runtimeType == other.runtimeType &&
          vitalType == other.vitalType &&
          primaryValue == other.primaryValue &&
          secondaryValue == other.secondaryValue &&
          tertiaryValue == other.tertiaryValue &&
          unit == other.unit &&
          rawTranscript == other.rawTranscript &&
          warningMessage == other.warningMessage;

  @override
  int get hashCode => Object.hash(
        vitalType,
        primaryValue,
        secondaryValue,
        tertiaryValue,
        unit,
        rawTranscript,
        warningMessage,
      );
}

sealed class ParseResult {
  const ParseResult();
}

class ParseSuccess extends ParseResult {
  final ParsedReading reading;
  const ParseSuccess(this.reading);
}

class ParseFailure extends ParseResult {
  final String message;
  final String rawTranscript;
  const ParseFailure(this.message, {required this.rawTranscript});
}

class VitalParser {
  /// Parses a spoken transcript into a [ParseResult].
  static ParseResult parse(String transcript) {
    final cleaned = transcript.trim();
    if (cleaned.isEmpty) {
      return const ParseFailure(
        'No voice input detected. Please hold the mic and speak clearly.',
        rawTranscript: '',
      );
    }

    final lower = cleaned.toLowerCase();

    // 1. Identify vital type by matching reserved keywords
    VitalType? matchedType;
    String matchedTrigger = '';

    // Collect all triggers sorted by length descending so longer phrases
    // ("blood pressure") are evaluated before shorter ("pressure")
    final allTriggers = <_TriggerMatch>[];
    for (final type in VitalType.values) {
      for (final trigger in type.triggers) {
        allTriggers.add(_TriggerMatch(type, trigger));
      }
    }
    allTriggers.sort((a, b) => b.trigger.length.compareTo(a.trigger.length));

    // Find all matches in the transcript with their start positions
    final matches = <_FoundMatch>[];
    for (final tm in allTriggers) {
      final pattern = RegExp('\\b${RegExp.escape(tm.trigger)}\\b');
      final match = pattern.firstMatch(lower);
      if (match != null) {
        // Prevent matching sub-parts of already matched longer triggers
        final overlaps = matches.any((m) =>
            (match.start >= m.start && match.start < m.end) ||
            (match.end > m.start && match.end <= m.end));
        if (!overlaps) {
          matches.add(_FoundMatch(tm.type, tm.trigger, match.start, match.end));
        }
      }
    }

    if (matches.isNotEmpty) {
      // Sort matches by start position in sentence. The earliest keyword determines vital type.
      matches.sort((a, b) => a.start.compareTo(b.start));
      matchedType = matches.first.type;
      matchedTrigger = matches.first.trigger;
    }

    // Fallback: If no explicit trigger word but transcript contains "over" or "/" with numbers (e.g. "120 over 80")
    if (matchedType == null && (lower.contains('over') || lower.contains('/'))) {
      final testNums = SpokenNumberParser.extractNumbers(lower);
      if (testNums.length >= 2) {
        matchedType = VitalType.bloodPressure;
        matchedTrigger = '';
      }
    }

    if (matchedType == null) {
      return ParseFailure(
        'Could not identify vital sign. Speak a reserved word (e.g., "Glucose 120", "Blood Pressure 120 over 80", "BP 135 74 93", "Pulse 72").',
        rawTranscript: cleaned,
      );
    }

    // 2. Remove the matched trigger from the transcript to isolate numbers
    String withoutTrigger = lower;
    if (matchedTrigger.isNotEmpty) {
      withoutTrigger = withoutTrigger.replaceFirst(
        RegExp('\\b${RegExp.escape(matchedTrigger)}\\b'),
        ' ',
      );
    }

    // If blood pressure was identified, also strip secondary words like "pulse" or "heart rate"
    // so in "BP 135 over 74 pulse 93", the number 93 is parsed cleanly as pulse
    if (matchedType == VitalType.bloodPressure) {
      for (final trigger in VitalType.heartRate.triggers) {
        withoutTrigger = withoutTrigger.replaceAll(
          RegExp('\\b${RegExp.escape(trigger)}\\b'),
          ' ',
        );
      }
    }

    // 3. Extract numbers
    final numbers = SpokenNumberParser.extractNumbers(withoutTrigger);

    if (numbers.isEmpty) {
      return ParseFailure(
        'Identified "${matchedType.displayName}" but did not detect any number.',
        rawTranscript: cleaned,
      );
    }

    if (matchedType == VitalType.bloodPressure) {
      if (numbers.length < 2) {
        return ParseFailure(
          'Blood pressure requires at least systolic and diastolic numbers (e.g. "BP 120 over 80" or "BP 135 74 93").',
          rawTranscript: cleaned,
        );
      }
      final systolic = numbers[0];
      final diastolic = numbers[1];
      // 3rd value is Pulse / Heart rate (e.g. 135 74 93 -> Pulse 93)
      final double? pulse = numbers.length >= 3 ? numbers[2] : null;
      final warning = matchedType.validateRange(systolic, diastolic, pulse);

      return ParseSuccess(
        ParsedReading(
          vitalType: matchedType,
          primaryValue: systolic,
          secondaryValue: diastolic,
          tertiaryValue: pulse,
          unit: matchedType.defaultUnit,
          rawTranscript: cleaned,
          warningMessage: warning,
        ),
      );
    }

    // Single value vitals
    final primary = numbers.first;
    final warning = matchedType.validateRange(primary);

    return ParseSuccess(
      ParsedReading(
        vitalType: matchedType,
        primaryValue: primary,
        unit: matchedType.defaultUnit,
        rawTranscript: cleaned,
        warningMessage: warning,
      ),
    );
  }
}

class _FoundMatch {
  final VitalType type;
  final String trigger;
  final int start;
  final int end;
  const _FoundMatch(this.type, this.trigger, this.start, this.end);
}

class _TriggerMatch {
  final VitalType type;
  final String trigger;
  const _TriggerMatch(this.type, this.trigger);
}

