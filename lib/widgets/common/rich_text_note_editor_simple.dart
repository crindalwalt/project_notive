import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'dart:convert';
import '../../providers/note_provider.dart';
import '../../providers/theme_provider.dart';
import '../../data/models/note.dart';

class RichTextNoteEditor extends StatefulWidget {
  const RichTextNoteEditor({super.key});

  @override
  State<RichTextNoteEditor> createState() => _RichTextNoteEditorState();
}

class _RichTextNoteEditorState extends State<RichTextNoteEditor> {
  late TextEditingController _titleController;
  late QuillController _quillController;
  late FocusNode _titleFocusNode;
  late FocusNode _contentFocusNode;
  Note? _currentNote;
  bool _isModified = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _quillController = QuillController.basic();
    _titleFocusNode = FocusNode();
    _contentFocusNode = FocusNode();

    _titleController.addListener(_onTitleChanged);
    _quillController.addListener(_onContentChanged);
  }

  @override
  void dispose() {
    _saveNote();
    _titleController.dispose();
    _quillController.dispose();
    _titleFocusNode.dispose();
    _contentFocusNode.dispose();
    super.dispose();
  }

  void _updateControllersIfNeeded(Note? note) {
    if (note != _currentNote) {
      _saveNote();
      _currentNote = note;
      _isModified = false;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (note != null) {
          _titleController.text = note.title;
          
          // Load QuillDocument from plain text (we'll keep it simple for now)
          _quillController.document = Document()..insert(0, note.content);
        } else {
          _titleController.clear();
          _quillController.document = Document();
        }
      });
    }
  }

  void _onTitleChanged() {
    if (!_isModified) {
      setState(() {
        _isModified = true;
      });
    }
  }

  void _onContentChanged() {
    if (!_isModified) {
      setState(() {
        _isModified = true;
      });
    }
  }

  void _saveNote() {
    if (_currentNote != null && _isModified) {
      final noteProvider = context.read<NoteProvider>();
      final content = _quillController.document.toPlainText();
      
      noteProvider.updateNote(
        _currentNote!.id,
        title: _titleController.text.trim().isEmpty ? 'Untitled' : _titleController.text.trim(),
        content: content,
      );
      _isModified = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    
    return Consumer<NoteProvider>(
      builder: (context, noteProvider, child) {
        final note = noteProvider.selectedNote;
        _updateControllersIfNeeded(note);

        if (note == null) {
          return _buildEmptyState(isDark);
        }

        return _buildEditor(isDark);
      },
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        border: Border(
          left: BorderSide(
            color: isDark ? const Color(0xFF2D2D30) : const Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2D2D30) : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(60),
              ),
              child: Icon(
                Icons.note_add,
                size: 60,
                color: isDark ? const Color(0xFF6A6A6A) : const Color(0xFF9CA3AF),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No note selected',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFFCCCCCC) : const Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select a note from the sidebar or create a new one to start editing',
              style: TextStyle(
                fontSize: 16,
                color: isDark ? const Color(0xFF6A6A6A) : const Color(0xFF9CA3AF),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditor(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        border: Border(
          left: BorderSide(
            color: isDark ? const Color(0xFF2D2D30) : const Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          _buildHeader(isDark),
          _buildToolbar(isDark),
          Expanded(child: _buildContent(isDark)),
          _buildStatusBar(isDark),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252526) : const Color(0xFFFAFBFC),
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF2D2D30) : const Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _titleController,
              focusNode: _titleFocusNode,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF1F2937),
              ),
              decoration: InputDecoration(
                hintText: 'Note Title',
                hintStyle: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFF6A6A6A) : const Color(0xFF9CA3AF),
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          const SizedBox(width: 16),
          if (_isModified)
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFF3B82F6),
                shape: BoxShape.circle,
              ),
            ),
          const SizedBox(width: 16),
          IconButton(
            onPressed: () {
              final noteProvider = context.read<NoteProvider>();
              if (_currentNote != null) {
                noteProvider.togglePinNote(_currentNote!.id);
              }
            },
            icon: Icon(
              _currentNote?.isPinned == true ? Icons.push_pin : Icons.push_pin_outlined,
              size: 20,
            ),
            style: IconButton.styleFrom(
              foregroundColor: _currentNote?.isPinned == true 
                  ? const Color(0xFFF59E0B)
                  : (isDark ? const Color(0xFFCCCCCC) : const Color(0xFF6B7280)),
            ),
            tooltip: _currentNote?.isPinned == true ? 'Unpin Note' : 'Pin Note',
          ),
          IconButton(
            onPressed: _saveNote,
            icon: const Icon(Icons.save, size: 20),
            style: IconButton.styleFrom(
              foregroundColor: isDark ? const Color(0xFFCCCCCC) : const Color(0xFF6B7280),
            ),
            tooltip: 'Save Note',
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2D2D30) : const Color(0xFFF8F9FA),
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
      ),
      child: QuillSimpleToolbar(
        controller: _quillController,
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: QuillEditor.basic(
        controller: _quillController,
        focusNode: _contentFocusNode,
      ),
    );
  }

  Widget _buildStatusBar(bool isDark) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252526) : const Color(0xFFF8F9FA),
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF2D2D30) : const Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          if (_isModified)
            Row(
              children: [
                Icon(
                  Icons.circle,
                  size: 8,
                  color: isDark ? const Color(0xFF3B82F6) : const Color(0xFF3B82F6),
                ),
                const SizedBox(width: 8),
                Text(
                  'Modified',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          const Spacer(),
          Text(
            'Rich Text Editor • ${_quillController.document.toPlainText().length} characters',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? const Color(0xFF6A6A6A) : const Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }
}
