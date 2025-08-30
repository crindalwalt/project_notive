import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/folder_provider.dart';
import '../../providers/note_provider.dart';
import '../../data/models/folder.dart';
import '../../core/theme/app_theme.dart';
import 'create_folder_dialog.dart';

class FolderList extends StatelessWidget {
  const FolderList({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FolderProvider>(
      builder: (context, folderProvider, child) {
        if (folderProvider.isLoading) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }

        if (folderProvider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading folders',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  folderProvider.error!,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    folderProvider.clearError();
                    folderProvider.loadFolders();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final folders = folderProvider.rootFolders;

        return Column(
          children: [
            // Header with add button
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Folders',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _showCreateFolderDialog(context),
                    icon: const Icon(Icons.add, size: 18),
                    iconSize: 18,
                    splashRadius: 16,
                    tooltip: 'New folder',
                  ),
                ],
              ),
            ),
            // Folders list
            Expanded(
              child: folders.isEmpty
                  ? _buildEmptyState(context)
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      itemCount: folders.length,
                      itemBuilder: (context, index) {
                        final folder = folders[index];
                        return _FolderTile(folder: folder);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_outlined,
            size: 64,
            color: isDark
                ? AppTheme.darkSecondaryText
                : AppTheme.lightSecondaryText,
          ),
          const SizedBox(height: 16),
          Text(
            'No folders yet',
            style: theme.textTheme.titleMedium?.copyWith(
              color: isDark
                  ? AppTheme.darkSecondaryText
                  : AppTheme.lightSecondaryText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first folder to get started',
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showCreateFolderDialog(context),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Create Folder'),
          ),
        ],
      ),
    );
  }

  void _showCreateFolderDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const CreateFolderDialog(),
    );
  }
}

class _FolderTile extends StatefulWidget {
  final Folder folder;

  const _FolderTile({required this.folder});

  @override
  State<_FolderTile> createState() => _FolderTileState();
}

class _FolderTileState extends State<_FolderTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final folderProvider = context.watch<FolderProvider>();
    final isSelected = folderProvider.selectedFolder?.id == widget.folder.id;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 1),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppTheme.darkHover : AppTheme.lightHover)
              : _isHovered
              ? (isDark
                    ? AppTheme.darkHover.withOpacity(0.5)
                    : AppTheme.lightHover.withOpacity(0.5))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 2,
          ),
          leading: Icon(
            widget.folder.id == 'default'
                ? Icons.home_outlined
                : Icons.folder_outlined,
            size: 18,
            color: isDark
                ? AppTheme.darkSecondaryText
                : AppTheme.lightSecondaryText,
          ),
          title: Text(
            widget.folder.name,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
            ),
          ),
          onTap: () {
            folderProvider.selectFolder(widget.folder);
            context.read<NoteProvider>().loadNotesByFolder(widget.folder.id);
          },
          trailing: _isHovered && widget.folder.id != 'default'
              ? PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_horiz,
                    size: 16,
                    color: isDark
                        ? AppTheme.darkSecondaryText
                        : AppTheme.lightSecondaryText,
                  ),
                  iconSize: 16,
                  padding: EdgeInsets.zero,
                  splashRadius: 12,
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'rename',
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit, size: 16),
                          SizedBox(width: 8),
                          Text('Rename'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.delete, size: 16),
                          SizedBox(width: 8),
                          Text('Delete'),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) => _handleMenuAction(context, value),
                )
              : null,
        ),
      ),
    );
  }

  void _handleMenuAction(BuildContext context, String action) {
    final folderProvider = context.read<FolderProvider>();

    switch (action) {
      case 'rename':
        // TODO: Implement rename dialog
        break;
      case 'delete':
        _showDeleteConfirmation(context, folderProvider);
        break;
    }
  }

  void _showDeleteConfirmation(
    BuildContext context,
    FolderProvider folderProvider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Folder'),
        content: Text(
          'Are you sure you want to delete "${widget.folder.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              folderProvider.deleteFolder(widget.folder.id);
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
