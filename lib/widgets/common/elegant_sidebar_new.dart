import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/folder_provider.dart';
import '../../providers/note_provider.dart';
import '../../data/models/folder.dart';
import '../../data/models/note.dart';
import '../dialogs/create_folder_dialog.dart';

class ElegantSidebar extends StatefulWidget {
  final bool isCollapsed;
  final VoidCallback onToggleCollapse;

  const ElegantSidebar({
    super.key,
    required this.isCollapsed,
    required this.onToggleCollapse,
  });

  @override
  State<ElegantSidebar> createState() => _ElegantSidebarState();
}

class _ElegantSidebarState extends State<ElegantSidebar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final Set<String> _expandedFolders = {};
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _loadData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _loadData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FolderProvider>().loadFolders();
      context.read<NoteProvider>().loadNotes();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: widget.isCollapsed ? 60 : 300,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF8F9FA),
        border: Border(
          right: BorderSide(
            color: isDark ? const Color(0xFF2D2D30) : const Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          _buildHeader(isDark),
          if (!widget.isCollapsed) _buildSearchBar(isDark),
          Expanded(child: _buildExplorer(isDark)),
          if (!widget.isCollapsed) _buildFooter(isDark),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252526) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF2D2D30) : const Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: widget.onToggleCollapse,
            icon: Icon(
              widget.isCollapsed ? Icons.menu : Icons.menu_open,
              size: 20,
            ),
            style: IconButton.styleFrom(
              foregroundColor: isDark
                  ? const Color(0xFFCCCCCC)
                  : const Color(0xFF374151),
              minimumSize: const Size(36, 36),
              padding: EdgeInsets.zero,
            ),
          ),
          if (!widget.isCollapsed) ...[
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'EXPLORER',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                  color: isDark
                      ? const Color(0xFFCCCCCC)
                      : const Color(0xFF6B7280),
                ),
              ),
            ),
            IconButton(
              onPressed: () => _createNewFolder(),
              icon: const Icon(Icons.create_new_folder, size: 16),
              style: IconButton.styleFrom(
                foregroundColor: isDark
                    ? const Color(0xFFCCCCCC)
                    : const Color(0xFF6B7280),
                minimumSize: const Size(28, 28),
                padding: EdgeInsets.zero,
              ),
              tooltip: 'New Folder',
            ),
            IconButton(
              onPressed: () => _createNewNote(),
              icon: const Icon(Icons.note_add, size: 16),
              style: IconButton.styleFrom(
                foregroundColor: isDark
                    ? const Color(0xFFCCCCCC)
                    : const Color(0xFF6B7280),
                minimumSize: const Size(28, 28),
                padding: EdgeInsets.zero,
              ),
              tooltip: 'New Note',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return Container(
      margin: const EdgeInsets.all(12),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value.toLowerCase();
          });
        },
        style: TextStyle(
          fontSize: 13,
          color: isDark ? const Color(0xFFCCCCCC) : const Color(0xFF374151),
        ),
        decoration: InputDecoration(
          hintText: 'Search files...',
          hintStyle: TextStyle(
            fontSize: 13,
            color: isDark ? const Color(0xFF6A6A6A) : const Color(0xFF9CA3AF),
          ),
          prefixIcon: Icon(
            Icons.search,
            size: 16,
            color: isDark ? const Color(0xFF6A6A6A) : const Color(0xFF9CA3AF),
          ),
          filled: true,
          fillColor: isDark ? const Color(0xFF2D2D30) : const Color(0xFFF3F4F6),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          isDense: true,
        ),
      ),
    );
  }

  Widget _buildExplorer(bool isDark) {
    if (widget.isCollapsed) {
      return _buildCollapsedView(isDark);
    }

    return Consumer2<FolderProvider, NoteProvider>(
      builder: (context, folderProvider, noteProvider, child) {
        final folders = folderProvider.folders;
        final notes = noteProvider.notes;

        return ListView(
          padding: const EdgeInsets.symmetric(vertical: 4),
          children: [
            ...folders.map(
              (folder) => _buildFolderTile(folder, noteProvider, isDark),
            ),
            ..._getRootNotes(
              notes,
            ).map((note) => _buildNoteTile(note, noteProvider, isDark, 0)),
          ],
        );
      },
    );
  }

  Widget _buildCollapsedView(bool isDark) {
    return Consumer<NoteProvider>(
      builder: (context, noteProvider, child) {
        return Column(
          children: [
            const SizedBox(height: 8),
            Tooltip(
              message: 'Create Folder',
              child: IconButton(
                onPressed: () => _createNewFolder(),
                icon: const Icon(Icons.folder, size: 20),
                style: IconButton.styleFrom(
                  foregroundColor: isDark
                      ? const Color(0xFFCCCCCC)
                      : const Color(0xFF6B7280),
                  minimumSize: const Size(36, 36),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Tooltip(
              message: 'Create Note',
              child: IconButton(
                onPressed: () => _createNewNote(),
                icon: const Icon(Icons.note, size: 20),
                style: IconButton.styleFrom(
                  foregroundColor: isDark
                      ? const Color(0xFFCCCCCC)
                      : const Color(0xFF6B7280),
                  minimumSize: const Size(36, 36),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFolderTile(
    Folder folder,
    NoteProvider noteProvider,
    bool isDark,
  ) {
    if (_searchQuery.isNotEmpty &&
        !folder.name.toLowerCase().contains(_searchQuery)) {
      return const SizedBox.shrink();
    }

    final isExpanded = _expandedFolders.contains(folder.id);
    final folderNotes = noteProvider.notes
        .where((note) => note.folderId == folder.id)
        .toList();

    return DragTarget<Map<String, dynamic>>(
      onAcceptWithDetails: (details) {
        final data = details.data;
        if (data['type'] == 'note') {
          final noteId = data['id'] as String;
          context.read<NoteProvider>().moveNoteToFolder(noteId, folder.id);
        } else if (data['type'] == 'folder') {
          final folderId = data['id'] as String;
          if (folderId != folder.id) {
            context.read<FolderProvider>().updateFolder(
              folderId,
              parentId: folder.id,
            );
          }
        }
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Draggable<Map<String, dynamic>>(
              data: {'type': 'folder', 'id': folder.id},
              feedback: Material(
                color: Colors.transparent,
                child: Container(
                  width: 200,
                  height: 40,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: folder.color.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Text(folder.emoji, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          folder.name,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isHovering
                      ? folder.color.withOpacity(0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: isHovering
                      ? Border.all(color: folder.color, width: 2)
                      : null,
                ),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      if (isExpanded) {
                        _expandedFolders.remove(folder.id);
                      } else {
                        _expandedFolders.add(folder.id);
                      }
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isExpanded
                              ? Icons.keyboard_arrow_down
                              : Icons.keyboard_arrow_right,
                          size: 18,
                          color: isDark
                              ? const Color(0xFFCCCCCC)
                              : const Color(0xFF6B7280),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: folder.color.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              folder.emoji,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            folder.name,
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark
                                  ? const Color(0xFFCCCCCC)
                                  : const Color(0xFF374151),
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (folderNotes.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: folder.color.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${folderNotes.length}',
                              style: TextStyle(
                                fontSize: 11,
                                color: folder.color,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        const SizedBox(width: 4),
                        PopupMenuButton<String>(
                          icon: Icon(
                            Icons.more_horiz,
                            size: 16,
                            color: isDark
                                ? const Color(0xFF6A6A6A)
                                : const Color(0xFF9CA3AF),
                          ),
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit, size: 16),
                                  SizedBox(width: 8),
                                  Text('Edit'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.delete,
                                    size: 16,
                                    color: Colors.red,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Delete',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          onSelected: (value) =>
                              _handleFolderAction(folder, value),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (isExpanded)
              ...folderNotes.map(
                (note) => _buildNoteTile(note, noteProvider, isDark, 1),
              ),
          ],
        );
      },
    );
  }

  Widget _buildNoteTile(
    Note note,
    NoteProvider noteProvider,
    bool isDark,
    int level,
  ) {
    if (_searchQuery.isNotEmpty &&
        !note.title.toLowerCase().contains(_searchQuery)) {
      return const SizedBox.shrink();
    }

    final isSelected = noteProvider.selectedNote?.id == note.id;

    return Draggable<Map<String, dynamic>>(
      data: {'type': 'note', 'id': note.id},
      feedback: Material(
        color: Colors.transparent,
        child: Container(
          width: 200,
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2D2D30) : const Color(0xFFE5F3FF),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                Icons.description,
                size: 16,
                color: isDark
                    ? const Color(0xFF6A6A6A)
                    : const Color(0xFF9CA3AF),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  note.title.isEmpty ? 'Untitled' : note.title,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white : const Color(0xFF1F2937),
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
      child: InkWell(
        onTap: () => noteProvider.selectNote(note),
        child: Container(
          height: 48,
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          padding: EdgeInsets.only(
            left: 12 + (level * 20.0),
            right: 8,
            top: 8,
            bottom: 8,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? const Color(0xFF2D2D30) : const Color(0xFFE5F3FF))
                : null,
            borderRadius: BorderRadius.circular(6),
            border: isSelected
                ? Border.all(
                    color: isDark
                        ? const Color(0xFF007ACC)
                        : const Color(0xFF3B82F6),
                    width: 1,
                  )
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF6A6A6A).withOpacity(0.3)
                      : const Color(0xFF9CA3AF).withOpacity(0.3),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.description,
                  size: 14,
                  color: isDark
                      ? const Color(0xFF6A6A6A)
                      : const Color(0xFF9CA3AF),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  note.title.isEmpty ? 'Untitled' : note.title,
                  style: TextStyle(
                    fontSize: 13,
                    color: isSelected
                        ? (isDark ? Colors.white : const Color(0xFF1F2937))
                        : (isDark
                              ? const Color(0xFFCCCCCC)
                              : const Color(0xFF374151)),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (note.isPinned)
                Container(
                  margin: const EdgeInsets.only(right: 4),
                  child: Icon(
                    Icons.push_pin,
                    size: 12,
                    color: isDark
                        ? const Color(0xFFFFB020)
                        : const Color(0xFFF59E0B),
                  ),
                ),
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_horiz,
                  size: 14,
                  color: isDark
                      ? const Color(0xFF6A6A6A)
                      : const Color(0xFF9CA3AF),
                ),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'pin',
                    child: Row(
                      children: [
                        Icon(
                          note.isPinned
                              ? Icons.push_pin
                              : Icons.push_pin_outlined,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(note.isPinned ? 'Unpin' : 'Pin'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'rename',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 16),
                        SizedBox(width: 8),
                        Text('Rename'),
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
                onSelected: (value) =>
                    _handleNoteAction(note, value, noteProvider),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(bool isDark) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252526) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF2D2D30) : const Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Consumer<NoteProvider>(
              builder: (context, noteProvider, child) {
                final noteCount = noteProvider.notes.length;
                return Text(
                  '$noteCount notes',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? const Color(0xFF6A6A6A)
                        : const Color(0xFF9CA3AF),
                  ),
                );
              },
            ),
          ),
          IconButton(
            onPressed: () => context.read<ThemeProvider>().toggleTheme(),
            icon: Icon(
              context.watch<ThemeProvider>().isDarkMode
                  ? Icons.light_mode
                  : Icons.dark_mode,
              size: 16,
            ),
            style: IconButton.styleFrom(
              foregroundColor: isDark
                  ? const Color(0xFF6A6A6A)
                  : const Color(0xFF9CA3AF),
              minimumSize: const Size(28, 28),
              padding: EdgeInsets.zero,
            ),
            tooltip: 'Toggle Theme',
          ),
        ],
      ),
    );
  }

  List<Note> _getRootNotes(List<Note> notes) {
    return notes
        .where((note) => note.folderId.isEmpty || note.folderId == 'default')
        .toList();
  }

  void _createNewFolder() {
    showDialog(
      context: context,
      builder: (context) => const CreateFolderDialog(),
    );
  }

  void _createNewNote() {
    final folderProvider = context.read<FolderProvider>();
    final noteProvider = context.read<NoteProvider>();

    noteProvider.createNote(
      title: 'Untitled',
      content: '',
      folderId: folderProvider.selectedFolder?.id ?? 'default',
    );
  }

  void _handleFolderAction(Folder folder, String action) {
    switch (action) {
      case 'edit':
        showDialog(
          context: context,
          builder: (context) => CreateFolderDialog(
            folderId: folder.id,
            initialName: folder.name,
            initialEmoji: folder.emoji,
            initialColor: folder.color,
          ),
        );
        break;
      case 'delete':
        _showDeleteFolderDialog(folder);
        break;
    }
  }

  void _handleNoteAction(Note note, String action, NoteProvider noteProvider) {
    switch (action) {
      case 'pin':
        noteProvider.togglePinNote(note.id);
        break;
      case 'rename':
        _showRenameNoteDialog(note, noteProvider);
        break;
      case 'duplicate':
        noteProvider.createNote(
          title: '${note.title} (Copy)',
          content: note.content,
          folderId: note.folderId,
        );
        break;
      case 'delete':
        _showDeleteNoteDialog(note, noteProvider);
        break;
    }
  }

  void _showDeleteFolderDialog(Folder folder) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Folder'),
        content: Text('Are you sure you want to delete "${folder.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<FolderProvider>().deleteFolder(folder.id);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showDeleteNoteDialog(Note note, NoteProvider noteProvider) {
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
              noteProvider.deleteNote(note.id);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showRenameNoteDialog(Note note, NoteProvider noteProvider) {
    final controller = TextEditingController(text: note.title);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Note'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Note Title',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                noteProvider.updateNote(note.id, title: controller.text.trim());
              }
              Navigator.pop(context);
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }
}
