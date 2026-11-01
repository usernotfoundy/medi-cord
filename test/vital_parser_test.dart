import 'package:flutter_test/flutter_test.dart';
import 'package:medi_cord/core/parsing/number_words.dart';
import 'package:medi_cord/core/parsing/vital_parser.dart';
import 'package:medi_cord/core/vitals/vital_type.dart';

void main() {
  group('SpokenNumberParser', () {
    test('extracts direct numeric digits', () {
      expect(SpokenNumberParser.extractNumbers('120'), [120.0]);
      expect(SpokenNumberParser.extractNumbers('36.5'), [36.5]);
      expect(SpokenNumberParser.extractNumbers('120 over 80'), [120.0, 80.0]);
      expect(SpokenNumberParser.extractNumbers('120/80'), [120.0, 80.0]);
    });

    test('extracts words as numbers', () {
      expect(SpokenNumberParser.extractNumbers('one twenty'), [120.0]);
      expect(SpokenNumberParser.extractNumbers('one hundred twenty'), [120.0]);
      expect(SpokenNumberParser.extractNumbers('seventy two'), [72.0]);
      expect(SpokenNumberParser.extractNumbers('ninety eight'), [98.0]);
      expect(SpokenNumberParser.extractNumbers('thirty six point five'), [36.5]);
      expect(SpokenNumberParser.extractNumbers('one twenty over eighty'), [120.0, 80.0]);
    });
  });

  group('VitalParser', () {
    test('parses sample scenario: "Glucose 120"', () {
      final res = VitalParser.parse('Glucose 120');
      expect(res, isA<ParseSuccess>());
      final reading = (res as ParseSuccess).reading;
      expect(reading.vitalType, VitalType.glucose);
      expect(reading.primaryValue, 120.0);
      expect(reading.unit, 'mg/dL');
      expect(reading.warningMessage, isNull);
    });

    test('parses spoken words: "glucose one twenty"', () {
      final res = VitalParser.parse('glucose one twenty');
      expect(res, isA<ParseSuccess>());
      final reading = (res as ParseSuccess).reading;
      expect(reading.vitalType, VitalType.glucose);
      expect(reading.primaryValue, 120.0);
    });

    test('parses blood pressure with "over": "blood pressure 120 over 80"', () {
      final res = VitalParser.parse('blood pressure 120 over 80');
      expect(res, isA<ParseSuccess>());
      final reading = (res as ParseSuccess).reading;
      expect(reading.vitalType, VitalType.bloodPressure);
      expect(reading.primaryValue, 120.0);
      expect(reading.secondaryValue, 80.0);
      expect(reading.tertiaryValue, isNull);
      expect(reading.formattedValue, '120 / 80 mmHg');
    });

    test('parses blood pressure 2-value format: "BP 150 80" and "BP 150/80"', () {
      final resSpace = VitalParser.parse('BP 150 80');
      expect(resSpace, isA<ParseSuccess>());
      final readingSpace = (resSpace as ParseSuccess).reading;
      expect(readingSpace.primaryValue, 150.0);
      expect(readingSpace.secondaryValue, 80.0);
      expect(readingSpace.tertiaryValue, isNull);

      final resSlash = VitalParser.parse('BP 150/80');
      expect(resSlash, isA<ParseSuccess>());
      final readingSlash = (resSlash as ParseSuccess).reading;
      expect(readingSlash.primaryValue, 150.0);
      expect(readingSlash.secondaryValue, 80.0);
      expect(readingSlash.tertiaryValue, isNull);
    });

    test('parses blood pressure 3-value format: "BP 135 74 93"', () {
      final res = VitalParser.parse('BP 135 74 93');
      expect(res, isA<ParseSuccess>());
      final reading = (res as ParseSuccess).reading;
      expect(reading.vitalType, VitalType.bloodPressure);
      expect(reading.primaryValue, 135.0);
      expect(reading.secondaryValue, 74.0);
      expect(reading.tertiaryValue, 93.0);
      expect(reading.formattedValue, '135 / 74 mmHg • Pulse 93 bpm');
      expect(reading.warningMessage, isNull);
    });

    test('parses blood pressure 3-value format with words: "blood pressure 135 over 74 pulse 93"', () {
      final res = VitalParser.parse('blood pressure 135 over 74 pulse 93');
      expect(res, isA<ParseSuccess>());
      final reading = (res as ParseSuccess).reading;
      expect(reading.vitalType, VitalType.bloodPressure);
      expect(reading.primaryValue, 135.0);
      expect(reading.secondaryValue, 74.0);
      expect(reading.tertiaryValue, 93.0);
      expect(reading.formattedValue, '135 / 74 mmHg • Pulse 93 bpm');
    });

    test('flags warning if pulse in 3-value BP is outside normal range', () {
      final res = VitalParser.parse('BP 120 80 280');
      expect(res, isA<ParseSuccess>());
      final reading = (res as ParseSuccess).reading;
      expect(reading.warningMessage, isNotNull);
      expect(reading.warningMessage, contains('Pulse 280 bpm is outside typical range'));
    });

    test('parses temperature with decimal words: "temp thirty six point eight"', () {
      final res = VitalParser.parse('temp thirty six point eight');
      expect(res, isA<ParseSuccess>());
      final reading = (res as ParseSuccess).reading;
      expect(reading.vitalType, VitalType.temperature);
      expect(reading.primaryValue, closeTo(36.8, 0.01));
      expect(reading.unit, '°C');
    });

    test('parses heart rate / pulse: "pulse 72"', () {
      final res = VitalParser.parse('pulse 72');
      expect(res, isA<ParseSuccess>());
      final reading = (res as ParseSuccess).reading;
      expect(reading.vitalType, VitalType.heartRate);
      expect(reading.primaryValue, 72.0);
      expect(reading.unit, 'bpm');
    });

    test('parses oxygen saturation: "oxygen 98"', () {
      final res = VitalParser.parse('oxygen 98');
      expect(res, isA<ParseSuccess>());
      final reading = (res as ParseSuccess).reading;
      expect(reading.vitalType, VitalType.oxygenSaturation);
      expect(reading.primaryValue, 98.0);
      expect(reading.unit, '%');
    });

    test('flags warning if value is outside typical range', () {
      final res = VitalParser.parse('glucose 950');
      expect(res, isA<ParseSuccess>());
      final reading = (res as ParseSuccess).reading;
      expect(reading.warningMessage, isNotNull);
      expect(reading.warningMessage, contains('outside the typical range'));
    });

    test('returns failure if BP is missing diastolic number', () {
      final res = VitalParser.parse('BP 120');
      expect(res, isA<ParseFailure>());
      final failure = res as ParseFailure;
      expect(failure.message, contains('requires at least systolic and diastolic'));
    });

    test('returns failure if vital type unrecognized', () {
      final res = VitalParser.parse('hello there');
      expect(res, isA<ParseFailure>());
      final failure = res as ParseFailure;
      expect(failure.message, contains('Could not identify vital sign'));
    });

    test('returns failure if transcript empty', () {
      final res = VitalParser.parse('   ');
      expect(res, isA<ParseFailure>());
    });
  });
}

