import '../db/app_database.dart';
import '../models/vital_reading.dart';
import '../../core/vitals/vital_type.dart';

class VitalRepository {
  final AppDatabase _dbProvider;

  VitalRepository({AppDatabase? dbProvider})
      : _dbProvider = dbProvider ?? AppDatabase.instance;

  Future<VitalReading> insertReading(VitalReading reading) async {
    final db = await _dbProvider.database;
    final id = await db.insert('vital_readings', reading.toMap());
    return reading.copyWith(id: id);
  }

  Future<List<VitalReading>> getAllReadings() async {
    final db = await _dbProvider.database;
    final maps = await db.query(
      'vital_readings',
      orderBy: 'recorded_at DESC',
    );
    return maps.map((m) => VitalReading.fromMap(m)).toList();
  }

  Future<List<VitalReading>> getReadingsByType(VitalType type) async {
    final db = await _dbProvider.database;
    final maps = await db.query(
      'vital_readings',
      where: 'type = ?',
      whereArgs: [type.id],
      orderBy: 'recorded_at DESC',
    );
    return maps.map((m) => VitalReading.fromMap(m)).toList();
  }

  Future<List<VitalReading>> getReadingsForRange({
    required VitalType type,
    required DateTime start,
    required DateTime end,
  }) async {
    final db = await _dbProvider.database;
    final maps = await db.query(
      'vital_readings',
      where: 'type = ? AND recorded_at >= ? AND recorded_at <= ?',
      whereArgs: [
        type.id,
        start.millisecondsSinceEpoch,
        end.millisecondsSinceEpoch,
      ],
      orderBy: 'recorded_at ASC',
    );
    return maps.map((m) => VitalReading.fromMap(m)).toList();
  }

  Future<int> deleteReading(int id) async {
    final db = await _dbProvider.database;
    return await db.delete(
      'vital_readings',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> clearAll() async {
    final db = await _dbProvider.database;
    return await db.delete('vital_readings');
  }
}

