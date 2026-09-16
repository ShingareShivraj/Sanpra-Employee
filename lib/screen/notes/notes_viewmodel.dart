import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../model/note_model.dart';
import '../../services/notes/notes_service.dart';

class NotesViewModel extends ChangeNotifier {
  final NotesService _service;

  NotesViewModel({NotesService? service})
      : _service = service ?? NotesService();

  final List<NoteModel> _notes = [];
  Timer? _searchTimer;
  String _searchQuery = '';
  bool _initialLoading = false;
  bool _refreshing = false;
  bool _actionLoading = false;
  String? _error;
  int _requestGeneration = 0;

  List<NoteModel> get notes => List.unmodifiable(_notes);
  List<NoteModel> get pinnedNotes =>
      _notes.where((note) => note.isPinned).toList(growable: false);
  List<NoteModel> get regularNotes =>
      _notes.where((note) => !note.isPinned).toList(growable: false);

  String get searchQuery => _searchQuery;
  bool get isSearching => _searchQuery.isNotEmpty;
  bool get initialLoading => _initialLoading;
  bool get refreshing => _refreshing;
  bool get actionLoading => _actionLoading;
  String? get error => _error;
  bool get hasNotes => _notes.isNotEmpty;
  int get totalNotes => _notes.length;

  Future<void> initialise() async {
    if (_initialLoading) return;
    _initialLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _loadNotes();
    } catch (error) {
      _error = _message(error);
    } finally {
      _initialLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    if (_refreshing) return;
    _refreshing = true;
    _error = null;
    notifyListeners();
    try {
      await _loadNotes();
    } catch (error) {
      _error = _message(error);
    } finally {
      _refreshing = false;
      notifyListeners();
    }
  }

  void searchNotes(String value) {
    _searchQuery = value.trim();
    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(milliseconds: 300), () async {
      try {
        await _loadNotes();
      } catch (error) {
        _error = _message(error);
        notifyListeners();
      }
    });
  }

  Future<void> clearSearch() async {
    _searchTimer?.cancel();
    if (_searchQuery.isEmpty) return;
    _searchQuery = '';
    notifyListeners();
    try {
      await _loadNotes();
    } catch (error) {
      _error = _message(error);
      notifyListeners();
    }
  }

  Future<void> _loadNotes() async {
    final generation = ++_requestGeneration;
    final result = await _service.getAllNotes(search: _searchQuery);
    if (generation != _requestGeneration) return;
    _notes
      ..clear()
      ..addAll(result);
    _error = null;
    notifyListeners();
  }

  Future<NoteModel?> createNote({
    required String title,
    required String content,
    required bool isPinned,
    required int colorValue,
  }) async {
    return _runNoteAction(() => _service.createNote(
          title: title,
          content: content,
          isPinned: isPinned,
          colorValue: colorValue,
        ));
  }

  Future<NoteModel?> updateNote(NoteModel note) {
    return _runNoteAction(() => _service.updateNote(note));
  }

  Future<bool> deleteNote(NoteModel note) async {
    final id = note.id;
    if (id == null || _actionLoading) return false;
    _actionLoading = true;
    _error = null;
    notifyListeners();
    try {
      final deleted = await _service.deleteNote(id);
      if (deleted) _notes.removeWhere((item) => item.id == id);
      return deleted;
    } catch (error) {
      _error = _message(error);
      return false;
    } finally {
      _actionLoading = false;
      notifyListeners();
    }
  }

  Future<NoteModel?> togglePin(NoteModel note) {
    return _runNoteAction(() => _service.togglePin(note));
  }

  Future<NoteModel?> setNoteColor(NoteModel note, int colorValue) {
    return _runNoteAction(() => _service.setNoteColor(note, colorValue));
  }

  Future<NoteModel?> _runNoteAction(
    Future<NoteModel> Function() action,
  ) async {
    if (_actionLoading) return null;
    _actionLoading = true;
    _error = null;
    notifyListeners();
    try {
      final saved = await action();
      final index = _notes.indexWhere((note) => note.id == saved.id);
      if (index >= 0) {
        _notes[index] = saved;
      } else if (!isSearching) {
        _notes.add(saved);
      }
      _sortNotes();
      return saved;
    } catch (error) {
      _error = _message(error);
      return null;
    } finally {
      _actionLoading = false;
      notifyListeners();
    }
  }

  void _sortNotes() {
    _notes.sort((first, second) {
      if (first.isPinned != second.isPinned) {
        return first.isPinned ? -1 : 1;
      }
      final updatedCompare = second.updatedAt.compareTo(first.updatedAt);
      if (updatedCompare != 0) return updatedCompare;
      return (second.id ?? 0).compareTo(first.id ?? 0);
    });
  }

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  String _message(Object error) =>
      error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');

  @override
  void dispose() {
    _searchTimer?.cancel();
    super.dispose();
  }
}
