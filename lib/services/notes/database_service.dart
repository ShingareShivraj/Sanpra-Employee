import 'dart:async';

import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import '../../model/note_model.dart';

/// Common SQLite database layer for the Sanpra Employee application.
///
/// UI and ViewModels must not use sqflite directly. Feature services obtain a
/// database instance through this class.
class DatabaseService {
  DatabaseService._();

  static final DatabaseService instance = DatabaseService._();

  static const String databaseName = 'sanpra_employee.db';
  static const int databaseVersion = 2;

  Database? _database;
  Future<Database>? _openingDatabase;

  Future<Database> get database async {
    final existing = _database;
    if (existing != null && existing.isOpen) return existing;

    // All callers await the same future when the application requests the
    // database concurrently during startup.
    _openingDatabase ??= _openDatabase();
    try {
      final opened = await _openingDatabase!;
      _database = opened;
      return opened;
    } finally {
      _openingDatabase = null;
    }
  }

  Future<Database> _openDatabase() async {
    final databasesDirectory = await getDatabasesPath();
    final databasePath = path.join(databasesDirectory, databaseName);

    return openDatabase(
      databasePath,
      version: databaseVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await _createNotesTable(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        await _upgradeDatabase(db, oldVersion, newVersion);
      },
      onOpen: (db) async {
        // CREATE IF NOT EXISTS makes this safe when another local feature
        // created the shared database before My Notes was installed.
        await _createNotesTable(db);
        await _ensureColorColumn(db);
        await _createNotesIndexes(db);
      },
    );
  }

  Future<void> _createNotesTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${NoteModel.tableName} (
        ${NoteModel.columnId} INTEGER PRIMARY KEY AUTOINCREMENT,
        ${NoteModel.columnTitle} TEXT NOT NULL DEFAULT '',
        ${NoteModel.columnContent} TEXT NOT NULL DEFAULT '',
        ${NoteModel.columnIsPinned} INTEGER NOT NULL DEFAULT 0
          CHECK (${NoteModel.columnIsPinned} IN (0, 1)),
        ${NoteModel.columnColorValue} INTEGER NOT NULL DEFAULT 0,
        ${NoteModel.columnCreatedAt} TEXT NOT NULL,
        ${NoteModel.columnUpdatedAt} TEXT NOT NULL
      )
    ''');
    await _createNotesIndexes(db);
  }

  Future<void> _createNotesIndexes(DatabaseExecutor db) async {
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_notes_pinned_updated
      ON ${NoteModel.tableName} (
        ${NoteModel.columnIsPinned} DESC,
        ${NoteModel.columnUpdatedAt} DESC
      )
    ''');
  }

  Future<void> _upgradeDatabase(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await _ensureColorColumn(db);
    }
    await _createNotesIndexes(db);
  }

  Future<void> _ensureColorColumn(DatabaseExecutor db) async {
    if (!await _columnExists(
      db,
      NoteModel.tableName,
      NoteModel.columnColorValue,
    )) {
      await db.execute('''
        ALTER TABLE ${NoteModel.tableName}
        ADD COLUMN ${NoteModel.columnColorValue} INTEGER NOT NULL DEFAULT 0
      ''');
    }
  }

  Future<bool> _columnExists(
    DatabaseExecutor db,
    String table,
    String column,
  ) async {
    final columns = await db.rawQuery('PRAGMA table_info($table)');
    return columns.any((row) => row['name']?.toString() == column);
  }

  Future<T> transaction<T>(
    Future<T> Function(Transaction transaction) action,
  ) async {
    final db = await database;
    return db.transaction(action);
  }

  /// Closes the connection for tests or an intentional application shutdown.
  /// Normal screens do not need to call this method.
  Future<void> close() async {
    final db = _database;
    _database = null;
    _openingDatabase = null;
    if (db != null && db.isOpen) await db.close();
  }
}

