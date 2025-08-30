import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/note_provider.dart';
import '../../providers/theme_provider.dart';
import '../../data/models/note.dart';

class ElegantNoteEditor extends StatefulWidget {
  const ElegantNoteEditor({super.key});

  @override
  State<ElegantNoteEditor> createState() => _ElegantNoteEditorState();
}

class _ElegantNoteEditorState extends State<ElegantNoteEditor> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late FocusNode _titleFocusNode;
  late FocusNode _contentFocusNode;
  Note? _currentNote;
  bool _isModified = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _contentController = TextEditingController();
    _titleFocusNode = FocusNode();
    _contentFocusNode = FocusNode();

    _titleController.addListener(_onTitleChanged);
    _contentController.addListener(_onContentChanged);
  }

  @override
  void dispose() {
    _saveNote();
    _titleController.dispose();
    _contentController.dispose();
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
        if (mounted) {
          if (note != null) {
            _titleController.text = note.title;
            _contentController.text = note.content;
          } else {
            _titleController.clear();
            _contentController.clear();
          }
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
    _autoSave();
  }

  void _onContentChanged() {
    if (!_isModified) {
      setState(() {
        _isModified = true;
      });
    }
    _autoSave();
  }

  void _autoSave() {
    if (_currentNote != null) {
      context.read<NoteProvider>().autoSave(
        _currentNote!.id,
        _contentController.text,
        title: _titleController.text.trim(),
      );
    }
  }

  void _saveNote() {
    if (_currentNote != null && _isModified) {
      context.read<NoteProvider>().updateNote(
        _currentNote!.id,
        title: _titleController.text.trim(),
        content: _contentController.text,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NoteProvider>(
      builder: (context, noteProvider, child) {
        final selectedNote = noteProvider.selectedNote;
        _updateControllersIfNeeded(selectedNote);

        if (selectedNote == null) {
          return _buildEmptyState();
        }

        return _buildEditor(selectedNote);
      },
    );
  }

  Widget _buildEmptyState() {
    final isDark = context.watch<ThemeProvider>().isDarkMode;

    return Container(
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF2D2D30)
                    : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.edit_note_rounded,
                size: 50,
                color: isDark
                    ? const Color(0xFF6A6A6A)
                    : const Color(0xFF9CA3AF),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Select a note to start editing',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? const Color(0xFFCCCCCC)
                    : const Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose a note from the explorer or create a new one',
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? const Color(0xFF6A6A6A)
                    : const Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditor(Note note) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;

    return Container(
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      child: Column(
        children: [
          _buildEditorHeader(note, isDark),
          Expanded(child: _buildEditorContent(isDark)),
          _buildStatusBar(isDark),
        ],
      ),
    );
  }

  Widget _buildEditorHeader(Note note, bool isDark) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252526) : const Color(0xFFF8F9FA),
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF2D2D30) : const Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          if (_isModified)
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(right: 12),
              decoration: const BoxDecoration(
                color: Color(0xFF007ACC),
                shape: BoxShape.circle,
              ),
            ),
          Icon(
            Icons.description,
            size: 16,
            color: isDark ? const Color(0xFFCCCCCC) : const Color(0xFF6B7280),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              note.title.isEmpty ? 'Untitled' : note.title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? const Color(0xFFCCCCCC)
                    : const Color(0xFF374151),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          _buildHeaderActions(note, isDark),
        ],
      ),
    );
  }

  Widget _buildHeaderActions(Note note, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: _isModified ? _saveNote : null,
          icon: const Icon(Icons.save, size: 16),
          style: IconButton.styleFrom(
            foregroundColor: _isModified
                ? const Color(0xFF007ACC)
                : (isDark ? const Color(0xFF6A6A6A) : const Color(0xFF9CA3AF)),
            minimumSize: const Size(32, 32),
            padding: EdgeInsets.zero,
          ),
          tooltip: 'Save (Ctrl+S)',
        ),
        IconButton(
          onPressed: () {
            context.read<NoteProvider>().togglePinNote(note.id);
          },
          icon: Icon(
            note.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
            size: 16,
          ),
          style: IconButton.styleFrom(
            foregroundColor: note.isPinned
                ? const Color(0xFFFFB020)
                : (isDark ? const Color(0xFF6A6A6A) : const Color(0xFF9CA3AF)),
            minimumSize: const Size(32, 32),
            padding: EdgeInsets.zero,
          ),
          tooltip: note.isPinned ? 'Unpin' : 'Pin',
        ),
        PopupMenuButton<String>(
          icon: Icon(
            Icons.more_vert,
            size: 16,
            color: isDark ? const Color(0xFF6A6A6A) : const Color(0xFF9CA3AF),
          ),
          iconSize: 16,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'export',
              child: Row(
                children: [
                  Icon(Icons.download, size: 16),
                  SizedBox(width: 8),
                  Text('Export'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'duplicate',
              child: Row(
                children: [
                  Icon(Icons.copy, size: 16),
                  SizedBox(width: 8),
                  Text('Duplicate'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 16, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
          onSelected: (value) => _handleMenuAction(value, note),
        ),
      ],
    );
  }

  Widget _buildEditorContent(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title field
          TextField(
            controller: _titleController,
            focusNode: _titleFocusNode,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFFCCCCCC) : const Color(0xFF1F2937),
              height: 1.3,
            ),
            decoration: InputDecoration(
              hintText: 'Untitled Note',
              hintStyle: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? const Color(0xFF6A6A6A)
                    : const Color(0xFF9CA3AF),
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            maxLines: null,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) {
              _contentFocusNode.requestFocus();
            },
          ),

          const SizedBox(height: 16),

          // Divider
          Container(
            height: 1,
            color: isDark ? const Color(0xFF2D2D30) : const Color(0xFFE5E7EB),
          ),

          const SizedBox(height: 24),

          // Content field
          Expanded(
            child: TextField(
              controller: _contentController,
              focusNode: _contentFocusNode,
              style: TextStyle(
                fontSize: 16,
                color: isDark
                    ? const Color(0xFFCCCCCC)
                    : const Color(0xFF374151),
                height: 1.6,
                fontFamily: 'SF Pro Text',
              ),
              decoration: InputDecoration(
                hintText: 'Start writing your thoughts...',
                hintStyle: TextStyle(
                  fontSize: 16,
                  color: isDark
                      ? const Color(0xFF6A6A6A)
                      : const Color(0xFF9CA3AF),
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBar(bool isDark) {
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF007ACC) : const Color(0xFF3B82F6),
      ),
      child: Row(
        children: [
          Icon(Icons.circle, size: 8, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            'Markdown',
            style: const TextStyle(
              fontSize: 11,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            '${_getWordCount(_contentController.text)} words',
            style: const TextStyle(fontSize: 11, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Text(
            '${_getCharCount(_contentController.text)} chars',
            style: const TextStyle(fontSize: 11, color: Colors.white),
          ),
          if (_isModified) ...[
            const SizedBox(width: 16),
            const Text(
              'Modified',
              style: TextStyle(fontSize: 11, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }

  int _getWordCount(String content) {
    if (content.trim().isEmpty) return 0;
    return content.trim().split(RegExp(r'\s+')).length;
  }

  int _getCharCount(String content) {
    return content.length;
  }

  void _handleMenuAction(String action, Note note) {
    switch (action) {
      case 'export':
        _showSnackBar('Export functionality coming soon');
        break;
      case 'duplicate':
        context.read<NoteProvider>().createNote(
          title: '${note.title} (Copy)',
          content: note.content,
          folderId: note.folderId,
        );
        _showSnackBar('Note duplicated');
        break;
      case 'delete':
        _showDeleteDialog(note);
        break;
    }
  }

  void _showDeleteDialog(Note note) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: Text(
          'Are you sure you want to delete "${note.title.isEmpty ? 'Untitled' : note.title}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<NoteProvider>().deleteNote(note.id);
              Navigator.pop(context);
              _showSnackBar('Note deleted');
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
    );
  }
}
