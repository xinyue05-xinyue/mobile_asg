import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();
  Database? _database;

  Future<Database> get database async {
    if (_database case final database?) return database;

    final databasePath = await getDatabasesPath();
    _database = await openDatabase(
      path.join(databasePath, 'my_darah.db'),
      version: 2,
      onConfigure: (database) async {
        await database.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _createSchema,
      onUpgrade: _upgradeSchema,
    );
    return _database!;
  }

  Future<void> _createSchema(Database database, int version) async {
    await database.execute('''
      CREATE TABLE donation_centres (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        address TEXT NOT NULL,
        state TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        operating_hours TEXT,
        source_id TEXT,
        synced_at TEXT NOT NULL
      )
    ''');

    await database.execute('''
      CREATE TABLE donation_events (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        venue TEXT NOT NULL,
        starts_at TEXT NOT NULL,
        ends_at TEXT NOT NULL,
        status TEXT NOT NULL,
        description TEXT,
        synced_at TEXT NOT NULL
      )
    ''');

    await database.execute('''
      CREATE TABLE emergency_requests (
        id TEXT PRIMARY KEY,
        hospital_id TEXT NOT NULL,
        blood_type TEXT NOT NULL,
        units_needed INTEGER NOT NULL CHECK (units_needed > 0),
        urgency TEXT NOT NULL,
        deadline TEXT NOT NULL,
        status TEXT NOT NULL,
        synced_at TEXT NOT NULL
      )
    ''');

    await database.execute('''
      CREATE TABLE reward_transactions (
        id TEXT PRIMARY KEY,
        donor_id TEXT NOT NULL,
        points INTEGER NOT NULL,
        transaction_type TEXT NOT NULL,
        donation_id TEXT,
        created_at TEXT NOT NULL,
        synced_at TEXT NOT NULL
      )
    ''');

    await database.execute('''
      CREATE TABLE pending_sync (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        entity_type TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        operation TEXT NOT NULL,
        payload TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await _createGovernmentStats(database);
  }

  Future<void> _upgradeSchema(
    Database database,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) await _createGovernmentStats(database);
  }

  Future<void> _createGovernmentStats(Database database) async {
    await database.execute('''
      CREATE TABLE IF NOT EXISTS government_donation_stats (
        date TEXT NOT NULL,
        blood_type TEXT NOT NULL,
        donations INTEGER NOT NULL,
        synced_at TEXT NOT NULL,
        PRIMARY KEY (date, blood_type)
      )
    ''');
  }
}
