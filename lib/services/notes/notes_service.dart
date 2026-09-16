import 'package:sqflite/sqflite.dart';

import '../../model/note_model.dart';
import 'database_service.dart';

/// CRUD, search, pinning, and note-color operations for private local notes.
class NotesService {
  final DatabaseService _databaseService;

  NotesService({DatabaseService? databaseService})
      : _databaseService = databaseService ?? DatabaseService.instance;

  static const String _defaultOrder =
      '${NoteModel.columnIsPinned} DESC, '
      '${NoteModel.columnUpdatedAt} DESC, '
      '${NoteModel.columnId} DESC';

  Future<List<NoteModel>> getAllNotes({String? search}) async {
    final db = await _databaseService.database;
    final query = search?.trim() ?? '';

    final rows = query.isEmpty
        ? await db.query(
            NoteModel.tableName,
            orderBy: _defaultOrder,
          )
        : await db.query(
            NoteModel.tableName,
            where:
                "${NoteModel.columnTitle} LIKE ? ESCAPE '\\' "
                "OR ${NoteModel.columnContent} LIKE ? ESCAPE '\\'",
            whereArgs: [
              '%${_escapeLike(query)}%',
              '%${_escapeLike(query)}%',
            ],
            orderBy: _defaultOrder,
          );

    return rows.map(NoteModel.fromMap).toList(growable: false);
  }

  Future<List<NoteModel>> searchNotes(String query) {
    return getAllNotes(search: query);
  }

  Future<NoteModel?> getNote(int id) async {
    _validateId(id);
    final db = await _databaseService.database;
    final rows = await db.query(
      NoteModel.tableName,
      where: '${NoteModel.columnId} = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : NoteModel.fromMap(rows.first);
  }

  Future<NoteModel> createNote({
    required String title,
    required String content,
    bool isPinned = false,
    int colorValue = NoteModel.defaultColorValue,
  }) async {
    _validateNote(title, content);
    final now = DateTime.now();
    final note = NoteModel(
      title: title.trim(),
      content: _normalizeContent(content),
      isPinned: isPinned,
      colorValue: _normalizeColor(colorValue),
      createdAt: now,
      updatedAt: now,
    );

    final db = await _databaseService.database;
    final id = await db.insert(
      NoteModel.tableName,
      note.toMap(includeId: false),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
    return note.copyWith(id: id);
  }

  Future<NoteModel> updateNote(NoteModel note) async {
    final id = note.id;
    if (id == null) {
      throw const NotesServiceException(
        'A saved note ID is required for an update.',
      );
    }
    _validateNote(note.title, note.content);

    final updated = note.copyWith(
      title: note.title.trim(),
      content: _normalizeContent(note.content),
      colorValue: _normalizeColor(note.colorValue),
      updatedAt: DateTime.now(),
    );
    final db = await _databaseService.database;
    final affected = await db.update(
      NoteModel.tableName,
      updated.toMap(includeId: false),
      where: '${NoteModel.columnId} = ?',
      whereArgs: [id],
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
    if (affected == 0) {
      throw const NotesServiceException('The note no longer exists.');
    }
    return updated;
  }

  Future<bool> deleteNote(int id) async {
    _validateId(id);
    final db = await _databaseService.database;
    final affected = await db.delete(
      NoteModel.tableName,
      where: '${NoteModel.columnId} = ?',
      whereArgs: [id],
    );
    return affected > 0;
  }

  Future<NoteModel> togglePin(NoteModel note) {
    return updateNote(note.copyWith(isPinned: !note.isPinned));
  }

  Future<NoteModel> setPinned(NoteModel note, bool isPinned) {
    if (note.isPinned == isPinned) return Future.value(note);
    return updateNote(note.copyWith(isPinned: isPinned));
  }

  Future<NoteModel> setNoteColor(NoteModel note, int colorValue) {
    final normalized = _normalizeColor(colorValue);
    if (note.colorValue == normalized) return Future.value(note);
    return updateNote(note.copyWith(colorValue: normalized));
  }

  Future<int> getNotesCount() async {
    final db = await _databaseService.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) AS total FROM ${NoteModel.tableName}',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  void _validateNote(String title, String content) {
    if (title.trim().isEmpty && content.trim().isEmpty) {
      throw const NotesServiceException(
        'Enter a title or some note content before saving.',
      );
    }
  }

  void _validateId(int id) {
    if (id <= 0) {
      throw const NotesServiceException('Please provide a valid note ID.');
    }
  }

  int _normalizeColor(int value) {
    return value.clamp(0, 0xFFFFFFFF).toInt();
  }

  String _normalizeContent(String value) {
    // Preserve spaces, blank lines, numbered lists, and bullet formatting. Only
    // normalize platform-specific line endings for consistent SQLite storage.
    return value.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
  }

  String _escapeLike(String value) {
    return value
        .replaceAll('\\', '\\\\')
        .replaceAll('%', '\\%')
        .replaceAll('_', '\\_');
  }
}

class NotesServiceException implements Exception {
  final String message;

  const NotesServiceException(this.message);

  @override
  String toString() => message;
}
