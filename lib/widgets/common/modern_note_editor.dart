import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/note_provider.dart';
import '../../providers/theme_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/note.dart';

class ModernNoteEditor extends StatefulWidget {
  const ModernNoteEditor({super.key});

  @override
  State<ModernNoteEditor> createState() => _ModernNoteEditorState();
}

class _ModernNoteEditorState extends State<ModernNoteEditor> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late FocusNode _titleFocusNode;
  late FocusNode _contentFocusNode;
  bool _isModified = false;
  Note? _currentNote;

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
      _saveNote(); // Save current note before switching
      _currentNote = note;
      _isModified = false;

      // Schedule the controller update for after the current build cycle
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
          return _buildEmptyState(context);
        }

        return _buildEditor(context, selectedNote);
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkHover : AppTheme.lightHover,
                borderRadius: BorderRadius.circular(60),
              ),
              child: Icon(
                Icons.edit_note_rounded,
                size: 60,
                color: isDark
                    ? AppTheme.darkSecondaryText
                    : AppTheme.lightSecondaryText,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Select a note to edit',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppTheme.darkOnSurface
                    : AppTheme.lightOnSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Choose a note from the sidebar or create a new one',
              style: TextStyle(
                fontSize: 16,
                color: isDark
                    ? AppTheme.darkSecondaryText
                    : AppTheme.lightSecondaryText,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditor(BuildContext context, Note note) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
      ),
      child: Column(
        children: [
          _buildEditorHeader(context, note, isDark),
          Expanded(child: _buildEditorContent(context, note, isDark)),
        ],
      ),
    );
  }

  Widget _buildEditorHeader(BuildContext context, Note note, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    if (_isModified)
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: const BoxDecoration(
                          color: AppTheme.accentColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    Expanded(
                      child: Text(
                        'Editing Note',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? AppTheme.darkSecondaryText
                              : AppTheme.lightSecondaryText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _buildEditorActions(context, note, isDark),
            ],
          ),
          const SizedBox(height: 16),
          _buildTitleField(context, isDark),
        ],
      ),
    );
  }

  Widget _buildEditorActions(BuildContext context, Note note, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: _isModified ? _saveNote : null,
          icon: const Icon(Icons.save, size: 20),
          style: IconButton.styleFrom(
            backgroundColor: _isModified ? AppTheme.accentColor : null,
            foregroundColor: _isModified
                ? Colors.white
                : (isDark
                      ? AppTheme.darkSecondaryText
                      : AppTheme.lightSecondaryText),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          tooltip: 'Save (Ctrl+S)',
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: () {
            context.read<NoteProvider>().togglePinNote(_currentNote!.id);
          },
          icon: Icon(
            note.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
            size: 20,
          ),
          style: IconButton.styleFrom(
            backgroundColor: note.isPinned
                ? AppTheme.primaryColor.withOpacity(0.1)
                : null,
            foregroundColor: note.isPinned
                ? AppTheme.primaryColor
                : (isDark
                      ? AppTheme.darkSecondaryText
                      : AppTheme.lightSecondaryText),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          tooltip: note.isPinned ? 'Unpin' : 'Pin',
        ),
        const SizedBox(width: 8),
        PopupMenuButton<String>(
          icon: Icon(
            Icons.more_vert,
            size: 20,
            color: isDark
                ? AppTheme.darkSecondaryText
                : AppTheme.lightSecondaryText,
          ),
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
              value: 'share',
              child: Row(
                children: [
                  Icon(Icons.share, size: 16),
                  SizedBox(width: 8),
                  Text('Share'),
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
          onSelected: (value) => _handleMenuAction(context, value),
        ),
      ],
    );
  }

  Widget _buildTitleField(BuildContext context, bool isDark) {
    return TextField(
      controller: _titleController,
      focusNode: _titleFocusNode,
      style: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: isDark ? AppTheme.darkOnSurface : AppTheme.lightOnSurface,
        height: 1.2,
      ),
      decoration: InputDecoration(
        hintText: 'Untitled Note',
        hintStyle: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: isDark
              ? AppTheme.darkSecondaryText
              : AppTheme.lightSecondaryText,
        ),
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero,
      ),
      maxLines: null,
      textInputAction: TextInputAction.next,
      onSubmitted: (_) {
        _contentFocusNode.requestFocus();
      },
    );
  }

  Widget _buildEditorContent(BuildContext context, Note note, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildToolbar(context, isDark),
          const SizedBox(height: 20),
          Expanded(child: _buildContentField(context, isDark)),
        ],
      ),
    );
  }

  Widget _buildToolbar(BuildContext context, bool isDark) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
        ),
      ),
      child: Row(
        children: [
          _buildToolbarButton(
            Icons.format_bold,
            'Bold',
            () => _insertMarkdown('**', '**'),
          ),
          _buildToolbarButton(
            Icons.format_italic,
            'Italic',
            () => _insertMarkdown('*', '*'),
          ),
          _buildToolbarButton(
            Icons.code,
            'Code',
            () => _insertMarkdown('`', '`'),
          ),
          const SizedBox(width: 8),
          Container(
            width: 1,
            height: 20,
            color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
          ),
          const SizedBox(width: 8),
          _buildToolbarButton(
            Icons.format_list_bulleted,
            'List',
            () => _insertMarkdown('\n- ', ''),
          ),
          _buildToolbarButton(
            Icons.format_quote,
            'Quote',
            () => _insertMarkdown('\n> ', ''),
          ),
          _buildToolbarButton(
            Icons.link,
            'Link',
            () => _insertMarkdown('[', '](url)'),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkHover : AppTheme.lightHover,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '${_getWordCount(_contentController.text)} words',
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? AppTheme.darkSecondaryText
                    : AppTheme.lightSecondaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbarButton(
    IconData icon,
    String tooltip,
    VoidCallback onPressed,
  ) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;

    return Tooltip(
      message: tooltip,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        style: IconButton.styleFrom(
          foregroundColor: isDark
              ? AppTheme.darkSecondaryText
              : AppTheme.lightSecondaryText,
          minimumSize: const Size(32, 32),
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }

  Widget _buildContentField(BuildContext context, bool isDark) {
    return TextField(
      controller: _contentController,
      focusNode: _contentFocusNode,
      style: TextStyle(
        fontSize: 16,
        color: isDark ? AppTheme.darkOnSurface : AppTheme.lightOnSurface,
        height: 1.6,
      ),
      decoration: InputDecoration(
        hintText: 'Start writing your thoughts...',
        hintStyle: TextStyle(
          fontSize: 16,
          color: isDark
              ? AppTheme.darkSecondaryText
              : AppTheme.lightSecondaryText,
        ),
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero,
      ),
      maxLines: null,
      expands: true,
      textAlignVertical: TextAlignVertical.top,
    );
  }

  void _insertMarkdown(String prefix, String suffix) {
    final text = _contentController.text;
    final selection = _contentController.selection;

    if (selection.isValid) {
      final selectedText = text.substring(selection.start, selection.end);
      final newText = text.replaceRange(
        selection.start,
        selection.end,
        '$prefix$selectedText$suffix',
      );

      _contentController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
          offset:
              selection.start +
              prefix.length +
              selectedText.length +
              suffix.length,
        ),
      );
    } else {
      final newText = text + prefix + suffix;
      _contentController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
          offset: newText.length - suffix.length,
        ),
      );
    }

    _contentFocusNode.requestFocus();
  }

  int _getWordCount(String content) {
    return content
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .length;
  }

  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'export':
        _exportNote();
        break;
      case 'share':
        _shareNote();
        break;
      case 'duplicate':
        _duplicateNote(context);
        break;
      case 'delete':
        _deleteNote(context);
        break;
    }
  }

  void _exportNote() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Export functionality coming soon'),
        backgroundColor: AppTheme.accentColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _shareNote() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Share functionality coming soon'),
        backgroundColor: AppTheme.accentColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _duplicateNote(BuildContext context) {
    if (_currentNote != null) {
      context.read<NoteProvider>().createNote(
        title: '${_currentNote!.title} (Copy)',
        content: _currentNote!.content,
        folderId: _currentNote!.folderId,
      );
    }
  }

  void _deleteNote(BuildContext context) {
    if (_currentNote != null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Note'),
          content: Text(
            'Are you sure you want to delete "${_currentNote!.title.isEmpty ? 'Untitled' : _currentNote!.title}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                context.read<NoteProvider>().deleteNote(_currentNote!.id);
                Navigator.pop(context);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        ),
      );
    }
  }
}
