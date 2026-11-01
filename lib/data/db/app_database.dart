import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._init();
  static Database? _database;

  AppDatabase._init() {
    ensureInitialized();
  }

  static void ensureInitialized() {
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  }

  Future<Database> get database async {
    ensureInitialized();
    if (_database != null) return _database!;
    _database = await _initDB('medicord_vitals.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    ensureInitialized();

    final bool isDesktop =
        !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);
    final DatabaseFactory factory =
        isDesktop ? databaseFactoryFfi : databaseFactory;

    final String dbPath = await factory.getDatabasesPath();
    final path = p.join(dbPath, filePath);

    return await factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 2,
        onCreate: _createDB,
        onUpgrade: _upgradeDB,
      ),
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE vital_readings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        value_primary REAL NOT NULL,
        value_secondary REAL,
        value_tertiary REAL,
        unit TEXT NOT NULL,
        raw_transcript TEXT NOT NULL,
        recorded_at INTEGER NOT NULL,
        note TEXT
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_readings_type_time
      ON vital_readings (type, recorded_at DESC)
    ''');

    await db.execute('''
      CREATE INDEX idx_readings_time
      ON vital_readings (recorded_at DESC)
    ''');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE vital_readings ADD COLUMN value_tertiary REAL',
      );
    }
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
