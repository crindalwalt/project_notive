import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/note_provider.dart';
import '../../providers/folder_provider.dart';
import '../../providers/theme_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/note.dart';

class ModernNotesList extends StatefulWidget {
  const ModernNotesList({super.key});

  @override
  State<ModernNotesList> createState() => _ModernNotesListState();
}

class _ModernNotesListState extends State<ModernNotesList> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
        border: Border(
          right: BorderSide(
            color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
          ),
        ),
      ),
      child: Column(
        children: [
          _buildHeader(context, isDark),
          Expanded(child: _buildNotesList(context, isDark)),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Consumer<FolderProvider>(
                  builder: (context, folderProvider, child) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          folderProvider.selectedFolder?.name ?? 'All Notes',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppTheme.darkOnSurface
                                : AppTheme.lightOnSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Consumer<NoteProvider>(
                          builder: (context, noteProvider, child) {
                            return Text(
                              '${noteProvider.notes.length} notes',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? AppTheme.darkSecondaryText
                                    : AppTheme.lightSecondaryText,
                              ),
                            );
                          },
                        ),
                      ],
                    );
                  },
                ),
              ),
              _buildHeaderActions(context, isDark),
            ],
          ),
          const SizedBox(height: 16),
          _buildSearchField(context, isDark),
        ],
      ),
    );
  }

  Widget _buildHeaderActions(BuildContext context, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: () => _createNewNote(context),
          icon: const Icon(Icons.add, size: 20),
          style: IconButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            minimumSize: const Size(36, 36),
          ),
          tooltip: 'New Note',
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
              value: 'sort_title',
              child: Row(
                children: [
                  Icon(Icons.sort_by_alpha, size: 16),
                  SizedBox(width: 8),
                  Text('Sort by Title'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'sort_date',
              child: Row(
                children: [
                  Icon(Icons.access_time, size: 16),
                  SizedBox(width: 8),
                  Text('Sort by Date'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'view_grid',
              child: Row(
                children: [
                  Icon(Icons.grid_view, size: 16),
                  SizedBox(width: 8),
                  Text('Grid View'),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            // Handle menu actions
          },
        ),
      ],
    );
  }

  Widget _buildSearchField(BuildContext context, bool isDark) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkHover : AppTheme.lightHover,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
        ),
      ),
      child: TextField(
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        style: TextStyle(
          fontSize: 14,
          color: isDark ? AppTheme.darkOnSurface : AppTheme.lightOnSurface,
        ),
        decoration: InputDecoration(
          hintText: 'Search notes...',
          hintStyle: TextStyle(
            color: isDark
                ? AppTheme.darkSecondaryText
                : AppTheme.lightSecondaryText,
            fontSize: 14,
          ),
          prefixIcon: Icon(
            Icons.search,
            size: 18,
            color: isDark
                ? AppTheme.darkSecondaryText
                : AppTheme.lightSecondaryText,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                  icon: Icon(
                    Icons.clear,
                    size: 16,
                    color: isDark
                        ? AppTheme.darkSecondaryText
                        : AppTheme.lightSecondaryText,
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildNotesList(BuildContext context, bool isDark) {
    return Consumer2<NoteProvider, FolderProvider>(
      builder: (context, noteProvider, folderProvider, child) {
        if (noteProvider.isLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }

        if (noteProvider.error != null) {
          return _buildErrorState(context, noteProvider.error!, isDark);
        }

        final notes = _filterNotes(noteProvider.notes);

        if (notes.isEmpty) {
          return _buildEmptyState(context, isDark);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: notes.length,
          itemBuilder: (context, index) {
            final note = notes[index];
            final isSelected = noteProvider.selectedNote?.id == note.id;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildNoteCard(
                context,
                note,
                isSelected,
                isDark,
                () => noteProvider.selectNote(note),
              ),
            );
          },
        );
      },
    );
  }

  List<Note> _filterNotes(List<Note> notes) {
    if (_searchQuery.isEmpty) return notes;

    return notes.where((note) {
      return note.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          note.content.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  Widget _buildNoteCard(
    BuildContext context,
    Note note,
    bool isSelected,
    bool isDark,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark
                      ? AppTheme.primaryColor.withOpacity(0.15)
                      : AppTheme.primaryColor.withOpacity(0.08))
                : (isDark ? AppTheme.darkCard : AppTheme.lightCard),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? AppTheme.primaryColor.withOpacity(0.3)
                  : (isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
              width: isSelected ? 1.5 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      note.title.isEmpty ? 'Untitled' : note.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? AppTheme.primaryColor
                            : (isDark
                                  ? AppTheme.darkOnSurface
                                  : AppTheme.lightOnSurface),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (note.isPinned)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      child: Icon(
                        Icons.push_pin,
                        size: 14,
                        color: AppTheme.accentColor,
                      ),
                    ),
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_horiz,
                      size: 16,
                      color: isDark
                          ? AppTheme.darkSecondaryText
                          : AppTheme.lightSecondaryText,
                    ),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'pin',
                        child: Row(
                          children: [
                            Icon(
                              note.isPinned
                                  ? Icons.push_pin_outlined
                                  : Icons.push_pin,
                              size: 14,
                            ),
                            const SizedBox(width: 8),
                            Text(note.isPinned ? 'Unpin' : 'Pin'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'duplicate',
                        child: Row(
                          children: [
                            Icon(Icons.copy, size: 14),
                            SizedBox(width: 8),
                            Text('Duplicate'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 14),
                            SizedBox(width: 8),
                            Text('Delete'),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      _handleNoteAction(context, note, value);
                    },
                  ),
                ],
              ),
              if (note.content.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  _getPreviewText(note.content),
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? AppTheme.darkSecondaryText
                        : AppTheme.lightSecondaryText,
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 12,
                    color: isDark
                        ? AppTheme.darkSecondaryText
                        : AppTheme.lightSecondaryText,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(note.updatedAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? AppTheme.darkSecondaryText
                          : AppTheme.lightSecondaryText,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: (isDark
                          ? AppTheme.darkHover
                          : AppTheme.lightHover),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${_getWordCount(note.content)} words',
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark
                            ? AppTheme.darkSecondaryText
                            : AppTheme.lightSecondaryText,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkHover : AppTheme.lightHover,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.note_add_outlined,
                size: 40,
                color: isDark
                    ? AppTheme.darkSecondaryText
                    : AppTheme.lightSecondaryText,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No notes yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppTheme.darkOnSurface
                    : AppTheme.lightOnSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first note to get started',
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? AppTheme.darkSecondaryText
                    : AppTheme.lightSecondaryText,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _createNewNote(context),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Create Note'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: isDark
                  ? AppTheme.darkSecondaryText
                  : AppTheme.lightSecondaryText,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading notes',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppTheme.darkOnSurface
                    : AppTheme.lightOnSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? AppTheme.darkSecondaryText
                    : AppTheme.lightSecondaryText,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.read<NoteProvider>().loadNotes(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  String _getPreviewText(String content) {
    // Remove markdown formatting for preview
    return content
        .replaceAll(RegExp(r'[#*_`]'), '')
        .replaceAll(RegExp(r'\n+'), ' ')
        .trim();
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  int _getWordCount(String content) {
    return content
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .length;
  }

  void _createNewNote(BuildContext context) {
    final folderProvider = context.read<FolderProvider>();
    final noteProvider = context.read<NoteProvider>();

    if (folderProvider.selectedFolder == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a folder first'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    noteProvider.createNote(
      title: '',
      content: '',
      folderId: folderProvider.selectedFolder!.id,
    );
  }

  void _handleNoteAction(BuildContext context, Note note, String action) {
    final noteProvider = context.read<NoteProvider>();

    switch (action) {
      case 'pin':
        noteProvider.togglePinNote(note.id);
        break;
      case 'duplicate':
        noteProvider.createNote(
          title: '${note.title} (Copy)',
          content: note.content,
          folderId: note.folderId,
        );
        break;
      case 'delete':
        _showDeleteDialog(context, note);
        break;
    }
  }

  void _showDeleteDialog(BuildContext context, Note note) {
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
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
