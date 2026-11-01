import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:medi_cord/core/vitals/vital_type.dart';
import 'package:medi_cord/data/db/app_database.dart';
import 'package:medi_cord/data/models/vital_reading.dart';
import 'package:medi_cord/data/repositories/vital_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  });

  tearDownAll(() async {
    await AppDatabase.instance.close();
  });

  test('AppDatabase initializes and performs CRUD operations', () async {
    final repo = VitalRepository(dbProvider: AppDatabase.instance);

    await repo.clearAll();

    final reading = VitalReading(
      type: VitalType.glucose,
      valuePrimary: 120,
      unit: 'mg/dL',
      rawTranscript: 'Glucose 120',
      recordedAt: DateTime.now(),
    );

    final inserted = await repo.insertReading(reading);
    expect(inserted.id, isNotNull);

    final all = await repo.getAllReadings();
    expect(all.length, 1);
    expect(all.first.valuePrimary, 120);
    expect(all.first.type, VitalType.glucose);

    final deleted = await repo.deleteReading(inserted.id!);
    expect(deleted, 1);

    // Test 3-value Blood Pressure reading with pulse
    final bpReading = VitalReading(
      type: VitalType.bloodPressure,
      valuePrimary: 135,
      valueSecondary: 74,
      valueTertiary: 93,
      unit: 'mmHg',
      rawTranscript: 'BP 135 74 93',
      recordedAt: DateTime.now(),
    );

    final insertedBp = await repo.insertReading(bpReading);
    expect(insertedBp.id, isNotNull);

    final bpList = await repo.getAllReadings();
    expect(bpList.length, 1);
    expect(bpList.first.valuePrimary, 135);
    expect(bpList.first.valueSecondary, 74);
    expect(bpList.first.valueTertiary, 93);
    expect(bpList.first.formattedValue, '135 / 74 mmHg • Pulse 93 bpm');

    await repo.clearAll();
    final remaining = await repo.getAllReadings();
    expect(remaining.isEmpty, true);
  });
}

