import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../../providers/note_provider.dart';
import '../../providers/theme_provider.dart';
import '../../data/models/note.dart';

class SelectionBasedRichTextEditor extends StatefulWidget {
  const SelectionBasedRichTextEditor({super.key});

  @override
  State<SelectionBasedRichTextEditor> createState() =>
      _SelectionBasedRichTextEditorState();
}

class _SelectionBasedRichTextEditorState
    extends State<SelectionBasedRichTextEditor> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late FocusNode _titleFocusNode;
  late FocusNode _contentFocusNode;
  Note? _currentNote;
  bool _isModified = false;

  // Rich text formatting data
  List<TextSpanData> _formattedSpans = [];

  // Current toolbar state
  bool _isBold = false;
  bool _isItalic = false;
  bool _isUnderline = false;
  bool _isStrikethrough = false;
  TextAlign _textAlign = TextAlign.left;
  double _fontSize = 16.0;
  String _fontFamily = 'System Default';
  Color _textColor = Colors.black;
  Color _backgroundColor = Colors.transparent;

  final List<String> _fontFamilies = [
    'System Default',
    'Arial',
    'Times New Roman',
    'Courier New',
    'Helvetica',
    'Verdana',
    'Georgia',
    'Comic Sans MS',
  ];

  final List<double> _fontSizes = [
    8,
    9,
    10,
    11,
    12,
    14,
    16,
    18,
    20,
    24,
    28,
    32,
    36,
    48,
    72,
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _contentController = TextEditingController();
    _titleFocusNode = FocusNode();
    _contentFocusNode = FocusNode();

    _titleController.addListener(_onTitleChanged);
    _contentController.addListener(_onContentChanged);
    _contentController.addListener(_updateToolbarState);
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
        if (note != null) {
          _titleController.text = note.title;

          // Load formatted content
          try {
            if (note.content.isNotEmpty) {
              final Map<String, dynamic> contentData = jsonDecode(note.content);
              if (contentData.containsKey('text') &&
                  contentData.containsKey('spans')) {
                _contentController.text = contentData['text'];
                _formattedSpans = (contentData['spans'] as List)
                    .map((span) => TextSpanData.fromJson(span))
                    .toList();
              } else {
                // Legacy plain text
                _contentController.text = note.content;
                _formattedSpans = [];
              }
            } else {
              _contentController.clear();
              _formattedSpans = [];
            }
          } catch (e) {
            // If content is not valid JSON, treat as plain text
            _contentController.text = note.content;
            _formattedSpans = [];
          }
        } else {
          _titleController.clear();
          _contentController.clear();
          _formattedSpans = [];
        }
      });
    }
  }

  void _updateToolbarState() {
    final selection = _contentController.selection;
    if (selection.isValid && selection.start == selection.end) {
      // Cursor position - check format at cursor
      final spanAtCursor = _getSpanAtPosition(selection.start);
      if (spanAtCursor != null) {
        setState(() {
          _isBold = spanAtCursor.isBold;
          _isItalic = spanAtCursor.isItalic;
          _isUnderline = spanAtCursor.isUnderline;
          _isStrikethrough = spanAtCursor.isStrikethrough;
          _fontSize = spanAtCursor.fontSize;
          _fontFamily = spanAtCursor.fontFamily;
          _textColor = spanAtCursor.color;
          _backgroundColor = spanAtCursor.backgroundColor;
        });
      }
    }
  }

  TextSpanData? _getSpanAtPosition(int position) {
    int currentPos = 0;
    for (final span in _formattedSpans) {
      if (position >= currentPos && position < currentPos + span.text.length) {
        return span;
      }
      currentPos += span.text.length;
    }
    return null;
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

    // If we have no formatted spans and user started typing, create initial span
    if (_formattedSpans.isEmpty && _contentController.text.isNotEmpty) {
      setState(() {
        _formattedSpans = [
          TextSpanData(
            text: _contentController.text,
            fontSize: _fontSize,
            fontFamily: _fontFamily,
            color: _textColor,
            backgroundColor: _backgroundColor,
          ),
        ];
      });
    }

    // Sync text changes with spans
    if (_formattedSpans.isNotEmpty) {
      final currentText = _formattedSpans.map((span) => span.text).join();
      if (currentText != _contentController.text) {
        // Text was modified, update spans accordingly
        final newText = _contentController.text;
        if (newText.length > currentText.length) {
          // Text was added
          final addedText = newText.substring(currentText.length);
          setState(() {
            _formattedSpans.add(
              TextSpanData(
                text: addedText,
                fontSize: _fontSize,
                fontFamily: _fontFamily,
                color: _textColor,
                backgroundColor: _backgroundColor,
              ),
            );
          });
        } else if (newText.length < currentText.length) {
          // Text was removed - for now, recreate from plain text
          setState(() {
            _formattedSpans = newText.isEmpty
                ? []
                : [
                    TextSpanData(
                      text: newText,
                      fontSize: _fontSize,
                      fontFamily: _fontFamily,
                      color: _textColor,
                      backgroundColor: _backgroundColor,
                    ),
                  ];
          });
        }
      }
    }
  }

  void _saveNote() {
    if (_currentNote != null && _isModified) {
      final noteProvider = context.read<NoteProvider>();

      // Save as structured format
      final contentData = {
        'text': _contentController.text,
        'spans': _formattedSpans.map((span) => span.toJson()).toList(),
      };

      noteProvider.updateNote(
        _currentNote!.id,
        title: _titleController.text.trim().isEmpty
            ? 'Untitled'
            : _titleController.text.trim(),
        content: jsonEncode(contentData),
      );
      _isModified = false;
    }
  }

  void _applyFormatting({
    bool? bold,
    bool? italic,
    bool? underline,
    bool? strikethrough,
    double? fontSize,
    String? fontFamily,
    Color? textColor,
    Color? backgroundColor,
  }) {
    final selection = _contentController.selection;

    if (!selection.isValid) {
      _showSnackBar('Please place cursor in text or select text to format');
      return;
    }

    if (selection.isCollapsed) {
      _showSnackBar('Please select text to apply formatting');
      return;
    }

    final start = selection.start;
    final end = selection.end;
    final selectedText = _contentController.text.substring(start, end);

    // Create new span with selected formatting
    final newSpan = TextSpanData(
      text: selectedText,
      isBold: bold ?? _isBold,
      isItalic: italic ?? _isItalic,
      isUnderline: underline ?? _isUnderline,
      isStrikethrough: strikethrough ?? _isStrikethrough,
      fontSize: fontSize ?? _fontSize,
      fontFamily: fontFamily ?? _fontFamily,
      color: textColor ?? _textColor,
      backgroundColor: backgroundColor ?? _backgroundColor,
    );

    setState(() {
      _replaceTextRange(start, end, newSpan);
      _isModified = true;
    });
  }

  void _replaceTextRange(int start, int end, TextSpanData newSpan) {
    final newSpans = <TextSpanData>[];
    int currentPos = 0;
    bool spanAdded = false;

    for (final span in _formattedSpans) {
      final spanStart = currentPos;
      final spanEnd = currentPos + span.text.length;

      if (spanEnd <= start) {
        // Span is completely before selection
        newSpans.add(span);
      } else if (spanStart >= end) {
        // Span is completely after selection
        if (!spanAdded) {
          newSpans.add(newSpan);
          spanAdded = true;
        }
        newSpans.add(span);
      } else {
        // Span overlaps with selection
        if (spanStart < start) {
          // Add part before selection
          newSpans.add(
            TextSpanData(
              text: span.text.substring(0, start - spanStart),
              isBold: span.isBold,
              isItalic: span.isItalic,
              isUnderline: span.isUnderline,
              isStrikethrough: span.isStrikethrough,
              fontSize: span.fontSize,
              fontFamily: span.fontFamily,
              color: span.color,
              backgroundColor: span.backgroundColor,
            ),
          );
        }

        // Add new formatted span (only once)
        if (!spanAdded) {
          newSpans.add(newSpan);
          spanAdded = true;
        }

        if (spanEnd > end) {
          // Add part after selection
          newSpans.add(
            TextSpanData(
              text: span.text.substring(end - spanStart),
              isBold: span.isBold,
              isItalic: span.isItalic,
              isUnderline: span.isUnderline,
              isStrikethrough: span.isStrikethrough,
              fontSize: span.fontSize,
              fontFamily: span.fontFamily,
              color: span.color,
              backgroundColor: span.backgroundColor,
            ),
          );
        }
      }
      currentPos += span.text.length;
    }

    // If no spans exist or span wasn't added yet
    if (!spanAdded) {
      newSpans.add(newSpan);
    }

    _formattedSpans = newSpans;
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
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
                color: isDark
                    ? const Color(0xFF2D2D30)
                    : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(60),
              ),
              child: Icon(
                Icons.edit_note,
                size: 60,
                color: isDark
                    ? const Color(0xFF6A6A6A)
                    : const Color(0xFF9CA3AF),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No note selected',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? const Color(0xFFCCCCCC)
                    : const Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select a note from the sidebar or create a new one to start editing',
              style: TextStyle(
                fontSize: 16,
                color: isDark
                    ? const Color(0xFF6A6A6A)
                    : const Color(0xFF9CA3AF),
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
          _buildFormattingToolbar(isDark),
          _buildRuler(isDark),
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
                hintText: 'Document Title',
                hintStyle: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? const Color(0xFF6A6A6A)
                      : const Color(0xFF9CA3AF),
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
              _currentNote?.isPinned == true
                  ? Icons.push_pin
                  : Icons.push_pin_outlined,
              size: 20,
            ),
            style: IconButton.styleFrom(
              foregroundColor: _currentNote?.isPinned == true
                  ? const Color(0xFFF59E0B)
                  : (isDark
                        ? const Color(0xFFCCCCCC)
                        : const Color(0xFF6B7280)),
            ),
            tooltip: _currentNote?.isPinned == true ? 'Unpin Note' : 'Pin Note',
          ),
          IconButton(
            onPressed: _saveNote,
            icon: const Icon(Icons.save, size: 20),
            style: IconButton.styleFrom(
              foregroundColor: isDark
                  ? const Color(0xFFCCCCCC)
                  : const Color(0xFF6B7280),
            ),
            tooltip: 'Save Note',
          ),
        ],
      ),
    );
  }

  Widget _buildFormattingToolbar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2D2D30) : const Color(0xFFF8F9FA),
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Font Family Dropdown
            Container(
              constraints: const BoxConstraints(minWidth: 120, maxWidth: 160),
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF404040)
                      : const Color(0xFFD1D5DB),
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _fontFamily,
                  isExpanded: true,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  items: _fontFamilies.map((font) {
                    return DropdownMenuItem(
                      value: font,
                      child: Text(font, style: const TextStyle(fontSize: 12)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _fontFamily = value!;
                    });
                    _applyFormatting(fontFamily: value);
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Font Size Dropdown
            Container(
              width: 70,
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF404040)
                      : const Color(0xFFD1D5DB),
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<double>(
                  value: _fontSize,
                  isExpanded: true,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  items: _fontSizes.map((size) {
                    return DropdownMenuItem(
                      value: size,
                      child: Text(
                        '${size.toInt()}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _fontSize = value!;
                    });
                    _applyFormatting(fontSize: value);
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Formatting Buttons
            _buildToggleButton(
              Icons.format_bold,
              _isBold,
              () {
                setState(() => _isBold = !_isBold);
                _applyFormatting(bold: _isBold);
              },
              'Bold',
              isDark,
            ),
            _buildToggleButton(
              Icons.format_italic,
              _isItalic,
              () {
                setState(() => _isItalic = !_isItalic);
                _applyFormatting(italic: _isItalic);
              },
              'Italic',
              isDark,
            ),
            _buildToggleButton(
              Icons.format_underlined,
              _isUnderline,
              () {
                setState(() => _isUnderline = !_isUnderline);
                _applyFormatting(underline: _isUnderline);
              },
              'Underline',
              isDark,
            ),
            _buildToggleButton(
              Icons.format_strikethrough,
              _isStrikethrough,
              () {
                setState(() => _isStrikethrough = !_isStrikethrough);
                _applyFormatting(strikethrough: _isStrikethrough);
              },
              'Strikethrough',
              isDark,
            ),

            const SizedBox(width: 8),
            Container(
              width: 1,
              height: 24,
              color: isDark ? const Color(0xFF404040) : const Color(0xFFD1D5DB),
            ),
            const SizedBox(width: 8),

            // Alignment Buttons
            _buildToggleButton(
              Icons.format_align_left,
              _textAlign == TextAlign.left,
              () => setState(() => _textAlign = TextAlign.left),
              'Align Left',
              isDark,
            ),
            _buildToggleButton(
              Icons.format_align_center,
              _textAlign == TextAlign.center,
              () => setState(() => _textAlign = TextAlign.center),
              'Align Center',
              isDark,
            ),
            _buildToggleButton(
              Icons.format_align_right,
              _textAlign == TextAlign.right,
              () => setState(() => _textAlign = TextAlign.right),
              'Align Right',
              isDark,
            ),
            _buildToggleButton(
              Icons.format_align_justify,
              _textAlign == TextAlign.justify,
              () => setState(() => _textAlign = TextAlign.justify),
              'Justify',
              isDark,
            ),

            const SizedBox(width: 8),
            Container(
              width: 1,
              height: 24,
              color: isDark ? const Color(0xFF404040) : const Color(0xFFD1D5DB),
            ),
            const SizedBox(width: 8),

            // Color Buttons
            _buildColorButton(
              Icons.format_color_text,
              _textColor,
              'Text Color',
              isDark,
              (color) => _applyFormatting(textColor: color),
            ),
            _buildColorButton(
              Icons.format_color_fill,
              _backgroundColor,
              'Highlight Color',
              isDark,
              (color) => _applyFormatting(backgroundColor: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButton(
    IconData icon,
    bool isActive,
    VoidCallback onPressed,
    String tooltip,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.only(right: 2),
      child: Tooltip(
        message: tooltip,
        child: IconButton(
          onPressed: onPressed,
          icon: Icon(icon, size: 18),
          style: IconButton.styleFrom(
            backgroundColor: isActive
                ? (isDark ? const Color(0xFF404040) : const Color(0xFFE5F3FF))
                : Colors.transparent,
            foregroundColor: isActive
                ? (isDark ? Colors.white : const Color(0xFF3B82F6))
                : (isDark ? const Color(0xFFCCCCCC) : const Color(0xFF6B7280)),
            minimumSize: const Size(32, 32),
            padding: const EdgeInsets.all(4),
          ),
        ),
      ),
    );
  }

  Widget _buildColorButton(
    IconData icon,
    Color currentColor,
    String tooltip,
    bool isDark,
    Function(Color) onColorChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(right: 2),
      child: Tooltip(
        message: tooltip,
        child: IconButton(
          onPressed: () =>
              _showColorPicker(currentColor, onColorChanged, isDark),
          icon: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isDark
                    ? const Color(0xFFCCCCCC)
                    : const Color(0xFF6B7280),
              ),
              Container(
                height: 3,
                width: 16,
                decoration: BoxDecoration(
                  color: currentColor == Colors.transparent
                      ? (isDark ? Colors.white : Colors.black)
                      : currentColor,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ],
          ),
          style: IconButton.styleFrom(
            minimumSize: const Size(32, 32),
            padding: const EdgeInsets.all(4),
          ),
        ),
      ),
    );
  }

  void _showColorPicker(
    Color currentColor,
    Function(Color) onColorChanged,
    bool isDark,
  ) {
    final colors = [
      Colors.transparent,
      Colors.black,
      Colors.white,
      Colors.red.shade600,
      Colors.green.shade600,
      Colors.blue.shade600,
      Colors.yellow.shade600,
      Colors.orange.shade600,
      Colors.purple.shade600,
      Colors.pink.shade600,
      Colors.cyan.shade600,
      Colors.indigo.shade600,
      Colors.teal.shade600,
      Colors.lime.shade600,
      Colors.amber.shade600,
      Colors.deepOrange.shade600,
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Color'),
        content: SizedBox(
          width: 240,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: colors.map((color) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (onColorChanged.toString().contains('textColor')) {
                      _textColor = color;
                    } else {
                      _backgroundColor = color;
                    }
                  });
                  onColorChanged(color);
                  Navigator.pop(context);
                },
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color == Colors.transparent
                        ? (isDark
                              ? const Color(0xFF2D2D30)
                              : const Color(0xFFF3F4F6))
                        : color,
                    border: Border.all(
                      color: color == currentColor
                          ? (isDark ? Colors.white : Colors.black)
                          : (isDark
                                ? const Color(0xFF404040)
                                : const Color(0xFFD1D5DB)),
                      width: color == currentColor ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: color == Colors.transparent
                      ? Icon(
                          Icons.format_color_reset,
                          size: 16,
                          color: isDark ? Colors.white : Colors.black,
                        )
                      : null,
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildRuler(bool isDark) {
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 24),
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
        children: [Expanded(child: CustomPaint(painter: RulerPainter(isDark)))],
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : Colors.grey).withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: _formattedSpans.isEmpty
          ? TextField(
              controller: _contentController,
              focusNode: _contentFocusNode,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.white : Colors.black,
                height: 1.6,
              ),
              textAlign: _textAlign,
              decoration: InputDecoration(
                hintText:
                    'Start writing your document...\n\nTip: Select text first, then apply formatting.',
                hintStyle: TextStyle(
                  fontSize: 16,
                  color: isDark
                      ? const Color(0xFF6A6A6A)
                      : const Color(0xFF9CA3AF),
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            )
          : SingleChildScrollView(
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(minHeight: 400),
                child: _buildRichText(isDark),
              ),
            ),
    );
  }

  Widget _buildRichText(bool isDark) {
    if (_formattedSpans.isEmpty) {
      return GestureDetector(
        onTap: () => _contentFocusNode.requestFocus(),
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Text(
            'Start writing your document...\n\nTip: Select text first, then apply formatting.',
            style: TextStyle(
              fontSize: 16,
              color: isDark ? const Color(0xFF6A6A6A) : const Color(0xFF9CA3AF),
              height: 1.6,
            ),
          ),
        ),
      );
    }

    List<InlineSpan> spans = [];
    for (final spanData in _formattedSpans) {
      spans.add(
        TextSpan(
          text: spanData.text,
          style: TextStyle(
            fontSize: spanData.fontSize,
            fontWeight: spanData.isBold ? FontWeight.bold : FontWeight.normal,
            fontStyle: spanData.isItalic ? FontStyle.italic : FontStyle.normal,
            decoration: _buildTextDecoration(spanData),
            color: spanData.color == Colors.transparent
                ? (isDark ? Colors.white : Colors.black)
                : spanData.color,
            backgroundColor: spanData.backgroundColor == Colors.transparent
                ? null
                : spanData.backgroundColor,
            fontFamily: spanData.fontFamily == 'System Default'
                ? null
                : spanData.fontFamily,
            height: 1.6,
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        // Focus the hidden text field for editing
        _contentFocusNode.requestFocus();
      },
      child: Stack(
        children: [
          // Visible rich text
          SelectableText.rich(
            TextSpan(children: spans),
            textAlign: _textAlign,
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.white : Colors.black,
              height: 1.6,
            ),
          ),
          // Hidden text field for text input
          Positioned.fill(
            child: Opacity(
              opacity: 0.0,
              child: TextField(
                controller: _contentController,
                focusNode: _contentFocusNode,
                maxLines: null,
                style: const TextStyle(color: Colors.transparent),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  TextDecoration _buildTextDecoration(TextSpanData spanData) {
    List<TextDecoration> decorations = [];

    if (spanData.isUnderline) {
      decorations.add(TextDecoration.underline);
    }
    if (spanData.isStrikethrough) {
      decorations.add(TextDecoration.lineThrough);
    }

    if (decorations.isEmpty) {
      return TextDecoration.none;
    } else if (decorations.length == 1) {
      return decorations.first;
    } else {
      return TextDecoration.combine(decorations);
    }
  }

  Widget _buildStatusBar(bool isDark) {
    final wordCount = _contentController.text
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .length;
    final charCount = _contentController.text.length;
    final selection = _contentController.selection;

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
                  color: isDark
                      ? const Color(0xFF3B82F6)
                      : const Color(0xFF3B82F6),
                ),
                const SizedBox(width: 8),
                Text(
                  'Modified',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? const Color(0xFF9CA3AF)
                        : const Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(width: 16),
              ],
            ),
          if (selection.isValid && !selection.isCollapsed)
            Text(
              'Selected: ${selection.end - selection.start} chars',
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? const Color(0xFF60A5FA)
                    : const Color(0xFF3B82F6),
              ),
            ),
          const Spacer(),
          Text(
            'Words: $wordCount | Characters: $charCount',
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

class TextSpanData {
  final String text;
  final bool isBold;
  final bool isItalic;
  final bool isUnderline;
  final bool isStrikethrough;
  final double fontSize;
  final String fontFamily;
  final Color color;
  final Color backgroundColor;

  const TextSpanData({
    required this.text,
    this.isBold = false,
    this.isItalic = false,
    this.isUnderline = false,
    this.isStrikethrough = false,
    this.fontSize = 16.0,
    this.fontFamily = 'System Default',
    this.color = Colors.black,
    this.backgroundColor = Colors.transparent,
  });

  Map<String, dynamic> toJson() => {
    'text': text,
    'isBold': isBold,
    'isItalic': isItalic,
    'isUnderline': isUnderline,
    'isStrikethrough': isStrikethrough,
    'fontSize': fontSize,
    'fontFamily': fontFamily,
    'color': color.value,
    'backgroundColor': backgroundColor.value,
  };

  factory TextSpanData.fromJson(Map<String, dynamic> json) => TextSpanData(
    text: json['text'],
    isBold: json['isBold'] ?? false,
    isItalic: json['isItalic'] ?? false,
    isUnderline: json['isUnderline'] ?? false,
    isStrikethrough: json['isStrikethrough'] ?? false,
    fontSize: json['fontSize']?.toDouble() ?? 16.0,
    fontFamily: json['fontFamily'] ?? 'System Default',
    color: Color(json['color'] ?? Colors.black.value),
    backgroundColor: Color(json['backgroundColor'] ?? Colors.transparent.value),
  );
}

class RulerPainter extends CustomPainter {
  final bool isDark;

  RulerPainter(this.isDark);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDark ? const Color(0xFF6A6A6A) : const Color(0xFF9CA3AF)
      ..strokeWidth = 1;

    // Draw ruler marks every 50 pixels
    for (int i = 0; i < size.width; i += 50) {
      canvas.drawLine(
        Offset(i.toDouble(), size.height - 8),
        Offset(i.toDouble(), size.height),
        paint,
      );
    }

    // Draw minor marks every 10 pixels
    for (int i = 0; i < size.width; i += 10) {
      if (i % 50 != 0) {
        canvas.drawLine(
          Offset(i.toDouble(), size.height - 4),
          Offset(i.toDouble(), size.height),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
