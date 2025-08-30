import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/folder.dart';
import '../../providers/folder_provider.dart';

class FoldersList extends StatelessWidget {
  const FoldersList({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FolderProvider>(
      builder: (context, folderProvider, child) {
        if (folderProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
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
                  onPressed: () => folderProvider.loadFolders(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (folderProvider.folders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.folder_outlined,
                  size: 64,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.4),
                ),
                const SizedBox(height: 16),
                Text(
                  'No folders yet',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Create your first folder to organize your notes',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.5),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => _showCreateFolderDialog(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Create Folder'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: folderProvider.folders.length,
          itemBuilder: (context, index) {
            final folder = folderProvider.folders[index];
            return FolderListItem(
              folder: folder,
              isSelected: folderProvider.selectedFolder?.id == folder.id,
              onTap: () => folderProvider.selectFolder(folder),
              onEdit: () => _showEditFolderDialog(context, folder),
              onDelete: () => _showDeleteFolderDialog(context, folder),
            );
          },
        );
      },
    );
  }

  void _showCreateFolderDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Folder'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Folder Name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              context.read<FolderProvider>().createFolder(value.trim());
              Navigator.of(context).pop();
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                context.read<FolderProvider>().createFolder(
                  controller.text.trim(),
                );
                Navigator.of(context).pop();
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showEditFolderDialog(BuildContext context, Folder folder) {
    final controller = TextEditingController(text: folder.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Folder'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Folder Name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
          onSubmitted: (value) {
            if (value.trim().isNotEmpty && value.trim() != folder.name) {
              context.read<FolderProvider>().updateFolder(
                folder.id,
                name: value.trim(),
              );
              Navigator.of(context).pop();
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty &&
                  controller.text.trim() != folder.name) {
                context.read<FolderProvider>().updateFolder(
                  folder.id,
                  name: controller.text.trim(),
                );
                Navigator.of(context).pop();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteFolderDialog(BuildContext context, Folder folder) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Folder'),
        content: Text(
          'Are you sure you want to delete "${folder.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<FolderProvider>().deleteFolder(folder.id);
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

class FolderListItem extends StatefulWidget {
  final Folder folder;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const FolderListItem({
    super.key,
    required this.folder,
    this.isSelected = false,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  State<FolderListItem> createState() => _FolderListItemState();
}

class _FolderListItemState extends State<FolderListItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: widget.isSelected
              ? theme.colorScheme.primary.withOpacity(0.1)
              : _isHovered
              ? theme.colorScheme.onSurface.withOpacity(0.05)
              : null,
          borderRadius: BorderRadius.circular(8),
          border: widget.isSelected
              ? Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.3),
                  width: 1,
                )
              : null,
        ),
        child: ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          leading: Icon(
            Icons.folder,
            color: widget.isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface.withOpacity(0.6),
            size: 20,
          ),
          title: Text(
            widget.folder.name,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: widget.isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface,
              fontWeight: widget.isSelected ? FontWeight.w500 : null,
            ),
          ),
          trailing: _isHovered || widget.isSelected
              ? PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_horiz,
                    size: 16,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        widget.onEdit?.call();
                        break;
                      case 'delete':
                        widget.onDelete?.call();
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: const [
                          Icon(Icons.edit, size: 16),
                          SizedBox(width: 8),
                          Text('Rename'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: const [
                          Icon(Icons.delete, size: 16),
                          SizedBox(width: 8),
                          Text('Delete'),
                        ],
                      ),
                    ),
                  ],
                )
              : null,
          onTap: widget.onTap,
        ),
      ),
    );
  }
}
