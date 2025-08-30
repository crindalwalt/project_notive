import '../database/database_helper.dart';
import '../models/note.dart';
import 'package:uuid/uuid.dart';

class NoteRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final Uuid _uuid = const Uuid();

  Future<List<Note>> getAllNotes() async {
    return await _databaseHelper.getAllNotes();
  }

  Future<List<Note>> getNotesByFolder(String folderId) async {
    return await _databaseHelper.getNotesByFolder(folderId);
  }

  Future<List<Note>> getPinnedNotes() async {
    return await _databaseHelper.getPinnedNotes();
  }

  Future<Note?> getNoteById(String id) async {
    return await _databaseHelper.getNoteById(id);
  }

  Future<String> createNote({
    required String title,
    required String content,
    required String folderId,
    bool isPinned = false,
  }) async {
    final note = Note(
      id: _uuid.v4(),
      title: title.trim().isEmpty ? 'Untitled Note' : title,
      content: content,
      folderId: folderId,
      isPinned: isPinned,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    return await _databaseHelper.insertNote(note);
  }

  Future<void> updateNote(
    String id, {
    String? title,
    String? content,
    String? folderId,
    bool? isPinned,
  }) async {
    final existingNote = await _databaseHelper.getNoteById(id);
    if (existingNote != null) {
      final updatedNote = existingNote.copyWith(
        title: title?.trim().isEmpty == true ? 'Untitled Note' : title,
        content: content,
        folderId: folderId,
        isPinned: isPinned,
        updatedAt: DateTime.now(),
      );
      await _databaseHelper.updateNote(updatedNote);
    }
  }

  Future<void> deleteNote(String id) async {
    await _databaseHelper.deleteNote(id);
  }

  Future<void> togglePinNote(String id) async {
    final note = await _databaseHelper.getNoteById(id);
    if (note != null) {
      final updatedNote = note.copyWith(
        isPinned: !note.isPinned,
        updatedAt: DateTime.now(),
      );
      await _databaseHelper.updateNote(updatedNote);
    }
  }

  Future<void> moveNoteToFolder(String noteId, String folderId) async {
    await updateNote(noteId, folderId: folderId);
  }

  Future<List<Note>> searchNotes(String query) async {
    if (query.trim().isEmpty) {
      return await getAllNotes();
    }
    return await _databaseHelper.searchNotes(query.trim());
  }

  Future<List<Note>> getRecentNotes({int limit = 10}) async {
    final allNotes = await getAllNotes();
    return allNotes.take(limit).toList();
  }
}
