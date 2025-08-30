import 'package:flutter/material.dart';
import '../data/models/note.dart';
import '../data/repositories/note_repository.dart';
import 'dart:async';

class NoteProvider with ChangeNotifier {
  final NoteRepository _repository = NoteRepository();

  List<Note> _notes = [];
  List<Note> _filteredNotes = [];
  Note? _selectedNote;
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  Timer? _autoSaveTimer;

  List<Note> get notes => _filteredNotes;
  Note? get selectedNote => _selectedNote;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;

  Future<void> loadNotes() async {
    _setLoading(true);
    try {
      _notes = await _repository.getAllNotes();
      _applyFilters();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadNotesByFolder(String folderId) async {
    _setLoading(true);
    try {
      _notes = await _repository.getNotesByFolder(folderId);
      _applyFilters();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadPinnedNotes() async {
    _setLoading(true);
    try {
      _notes = await _repository.getPinnedNotes();
      _applyFilters();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<String> createNote({
    required String title,
    required String content,
    required String folderId,
    bool isPinned = false,
  }) async {
    try {
      final noteId = await _repository.createNote(
        title: title,
        content: content,
        folderId: folderId,
        isPinned: isPinned,
      );

      // Reload notes to get the new note
      await loadNotesByFolder(folderId);

      // Select the newly created note
      final newNote = _notes.firstWhere((note) => note.id == noteId);
      selectNote(newNote);

      return noteId;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateNote(
    String id, {
    String? title,
    String? content,
    String? folderId,
    bool? isPinned,
  }) async {
    try {
      await _repository.updateNote(
        id,
        title: title,
        content: content,
        folderId: folderId,
        isPinned: isPinned,
      );

      // Update the selected note if it's the one being updated
      if (_selectedNote?.id == id) {
        final updatedNote = await _repository.getNoteById(id);
        if (updatedNote != null) {
          _selectedNote = updatedNote;
        }
      }

      // Reload notes to reflect changes
      await loadNotes();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteNote(String id) async {
    try {
      await _repository.deleteNote(id);

      // Clear selection if the deleted note was selected
      if (_selectedNote?.id == id) {
        _selectedNote = null;
      }

      await loadNotes();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> togglePinNote(String id) async {
    try {
      await _repository.togglePinNote(id);
      await loadNotes();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> moveNoteToFolder(String noteId, String folderId) async {
    try {
      await _repository.moveNoteToFolder(noteId, folderId);
      await loadNotes();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void selectNote(Note note) {
    _selectedNote = note;
    notifyListeners();
  }

  void clearSelection() {
    _selectedNote = null;
    notifyListeners();
  }

  void search(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  Future<void> searchNotes(String query) async {
    _setLoading(true);
    try {
      _notes = await _repository.searchNotes(query);
      _searchQuery = query;
      _applyFilters();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  void _applyFilters() {
    _filteredNotes = _notes;

    if (_searchQuery.isNotEmpty) {
      _filteredNotes = _notes.where((note) {
        return note.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            note.plainTextContent.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            );
      }).toList();
    }

    notifyListeners();
  }

  void autoSave(String noteId, String content, {String? title}) {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(seconds: 2), () {
      updateNote(noteId, content: content, title: title);
    });
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    super.dispose();
  }
}
