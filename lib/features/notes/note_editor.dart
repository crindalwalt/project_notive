import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/note_provider.dart';
import '../../data/models/note.dart';

class NoteEditor extends StatefulWidget {
  const NoteEditor({super.key});

  @override
  State<NoteEditor> createState() => _NoteEditorState();
}

class _NoteEditorState extends State<NoteEditor> {
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
            _contentController.text = note.plainTextContent;
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
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.note_add_outlined,
                  size: 64,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'Select a note to edit',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Or create a new note to get started',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Edit Note'),
            automaticallyImplyLeading: false,
            actions: [
              if (_isModified)
                IconButton(
                  icon: const Icon(Icons.save),
                  onPressed: _saveNote,
                  tooltip: 'Save',
                ),
              IconButton(
                icon: Icon(
                  _currentNote!.isPinned
                      ? Icons.push_pin
                      : Icons.push_pin_outlined,
                ),
                onPressed: () {
                  context.read<NoteProvider>().togglePinNote(_currentNote!.id);
                },
                tooltip: _currentNote!.isPinned ? 'Unpin' : 'Pin',
              ),
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () => _showOptionsMenu(context),
                tooltip: 'More options',
              ),
            ],
          ),
          body: Column(
            children: [
              // Title field
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _titleController,
                  focusNode: _titleFocusNode,
                  style: Theme.of(context).textTheme.headlineSmall,
                  decoration: const InputDecoration(
                    hintText: 'Note title...',
                    border: InputBorder.none,
                  ),
                  maxLines: 1,
                ),
              ),
              const Divider(height: 1),

              // Simple formatting toolbar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.format_bold),
                      onPressed: () => _insertMarkdown('**', '**'),
                      tooltip: 'Bold',
                    ),
                    IconButton(
                      icon: const Icon(Icons.format_italic),
                      onPressed: () => _insertMarkdown('*', '*'),
                      tooltip: 'Italic',
                    ),
                    IconButton(
                      icon: const Icon(Icons.format_list_bulleted),
                      onPressed: () => _insertMarkdown('- ', ''),
                      tooltip: 'Bullet List',
                    ),
                    IconButton(
                      icon: const Icon(Icons.format_list_numbered),
                      onPressed: () => _insertMarkdown('1. ', ''),
                      tooltip: 'Numbered List',
                    ),
                    IconButton(
                      icon: const Icon(Icons.format_quote),
                      onPressed: () => _insertMarkdown('> ', ''),
                      tooltip: 'Quote',
                    ),
                    const Spacer(),
                    Text(
                      'Characters: ${_contentController.text.length}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Content editor
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _contentController,
                    focusNode: _contentFocusNode,
                    style: Theme.of(context).textTheme.bodyLarge,
                    decoration: const InputDecoration(
                      hintText: 'Start writing your note...',
                      border: InputBorder.none,
                    ),
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                  ),
                ),
              ),
            ],
          ),
        );
      },
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

  void _showOptionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Delete Note'),
              onTap: () {
                Navigator.pop(context);
                _showDeleteDialog(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share Note'),
              onTap: () {
                Navigator.pop(context);
                _shareNote();
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy Content'),
              onTap: () {
                Navigator.pop(context);
                _copyContent();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: Text(
          'Are you sure you want to delete "${_currentNote!.title}"?',
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
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _shareNote() {
    // In a real app, you'd use the share_plus package
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share functionality not implemented yet')),
    );
  }

  void _copyContent() {
    // In a real app, you'd copy to clipboard
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Content copied to clipboard')),
    );
  }
}
