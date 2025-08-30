import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/folder.dart';
import '../../providers/folder_provider.dart';
import '../../providers/theme_provider.dart';
import '../../core/theme/app_theme.dart';

class ModernSidebar extends StatefulWidget {
  final bool isCollapsed;
  final VoidCallback onToggle;

  const ModernSidebar({
    super.key,
    required this.isCollapsed,
    required this.onToggle,
  });

  @override
  State<ModernSidebar> createState() => _ModernSidebarState();
}

class _ModernSidebarState extends State<ModernSidebar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _widthAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );

    _widthAnimation = Tween<double>(begin: 280.0, end: 60.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
      ),
    );

    if (widget.isCollapsed) {
      _animationController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(ModernSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCollapsed != oldWidget.isCollapsed) {
      if (widget.isCollapsed) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Container(
          width: _widthAnimation.value,
          decoration: BoxDecoration(
            color: isDark
                ? AppTheme.darkSidebarBackground
                : AppTheme.lightSidebarBackground,
            border: Border(
              right: BorderSide(
                color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                width: 1,
              ),
            ),
          ),
          child: Column(
            children: [
              _buildHeader(context, isDark),
              Expanded(child: _buildContent(context, isDark)),
              _buildFooter(context, isDark),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: widget.onToggle,
            icon: Icon(
              widget.isCollapsed ? Icons.menu : Icons.menu_open,
              size: 20,
            ),
            style: IconButton.styleFrom(
              foregroundColor: isDark
                  ? AppTheme.darkSecondaryText
                  : AppTheme.lightSecondaryText,
            ),
          ),
          if (!widget.isCollapsed) ...[
            const SizedBox(width: 8),
            Expanded(
              child: FadeTransition(
                opacity: _opacityAnimation,
                child: Text(
                  'Notive',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppTheme.darkOnSurface
                        : AppTheme.lightOnSurface,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, bool isDark) {
    if (widget.isCollapsed) {
      return _buildCollapsedContent(context, isDark);
    }
    return _buildExpandedContent(context, isDark);
  }

  Widget _buildCollapsedContent(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          _buildCollapsedButton(context, Icons.search, 'Search', () {}),
          const SizedBox(height: 4),
          _buildCollapsedButton(
            context,
            Icons.folder_outlined,
            'Folders',
            () {},
          ),
          const SizedBox(height: 4),
          _buildCollapsedButton(
            context,
            Icons.note_add_outlined,
            'New Note',
            () => _createNewNote(context),
          ),
        ],
      ),
    );
  }

  Widget _buildCollapsedButton(
    BuildContext context,
    IconData icon,
    String tooltip,
    VoidCallback onPressed,
  ) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;

    return Tooltip(
      message: tooltip,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        child: IconButton(
          onPressed: onPressed,
          icon: Icon(icon, size: 20),
          style: IconButton.styleFrom(
            foregroundColor: isDark
                ? AppTheme.darkSecondaryText
                : AppTheme.lightSecondaryText,
            backgroundColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedContent(BuildContext context, bool isDark) {
    return FadeTransition(
      opacity: _opacityAnimation,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildSearchBar(context, isDark),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildQuickActions(context, isDark),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Row(
                children: [
                  Text(
                    'Folders',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppTheme.darkSecondaryText
                          : AppTheme.lightSecondaryText,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => _showCreateFolderDialog(context),
                    icon: const Icon(Icons.add, size: 16),
                    style: IconButton.styleFrom(
                      foregroundColor: isDark
                          ? AppTheme.darkSecondaryText
                          : AppTheme.lightSecondaryText,
                      minimumSize: const Size(24, 24),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverFillRemaining(
            child: Consumer<FolderProvider>(
              builder: (context, folderProvider, child) {
                return _buildFolderTree(context, folderProvider, isDark);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, bool isDark) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkHover : AppTheme.lightHover,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
        ),
      ),
      child: TextField(
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
            size: 16,
            color: isDark
                ? AppTheme.darkSecondaryText
                : AppTheme.lightSecondaryText,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _buildQuickActionButton(
            context,
            Icons.note_add_outlined,
            'New Note',
            () => _createNewNote(context),
            isDark,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildQuickActionButton(
            context,
            Icons.folder_outlined,
            'New Folder',
            () => _showCreateFolderDialog(context),
            isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onPressed,
    bool isDark,
  ) {
    return Container(
      height: 32,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 14),
        label: Text(label, style: const TextStyle(fontSize: 12)),
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? AppTheme.darkCard : AppTheme.lightCard,
          foregroundColor: isDark
              ? AppTheme.darkSecondaryText
              : AppTheme.lightSecondaryText,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
            side: BorderSide(
              color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFolderTree(
    BuildContext context,
    FolderProvider folderProvider,
    bool isDark,
  ) {
    if (folderProvider.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (folderProvider.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 32,
                color: isDark
                    ? AppTheme.darkSecondaryText
                    : AppTheme.lightSecondaryText,
              ),
              const SizedBox(height: 8),
              Text(
                'Error loading folders',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppTheme.darkSecondaryText
                      : AppTheme.lightSecondaryText,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final rootFolders = folderProvider.rootFolders;

    if (rootFolders.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.folder_outlined,
                size: 32,
                color: isDark
                    ? AppTheme.darkSecondaryText
                    : AppTheme.lightSecondaryText,
              ),
              const SizedBox(height: 8),
              Text(
                'No folders yet',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppTheme.darkSecondaryText
                      : AppTheme.lightSecondaryText,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemCount: rootFolders.length,
      itemBuilder: (context, index) {
        return _buildFolderItem(
          context,
          rootFolders[index],
          folderProvider,
          isDark,
          0,
        );
      },
    );
  }

  Widget _buildFolderItem(
    BuildContext context,
    Folder folder,
    FolderProvider folderProvider,
    bool isDark,
    int depth,
  ) {
    final isSelected = folderProvider.selectedFolder?.id == folder.id;
    final subFolders = folderProvider.getSubFolders(folder.id);
    final hasSubFolders = subFolders.isNotEmpty;

    return Column(
      children: [
        Container(
          margin: EdgeInsets.only(left: depth * 16.0),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => folderProvider.selectFolder(folder),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark
                            ? AppTheme.primaryColor.withOpacity(0.15)
                            : AppTheme.primaryColor.withOpacity(0.1))
                      : null,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    if (hasSubFolders)
                      Icon(
                        Icons.keyboard_arrow_right,
                        size: 16,
                        color: isDark
                            ? AppTheme.darkSecondaryText
                            : AppTheme.lightSecondaryText,
                      )
                    else
                      const SizedBox(width: 16),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.folder_outlined,
                      size: 16,
                      color: isSelected
                          ? AppTheme.primaryColor
                          : (isDark
                                ? AppTheme.darkSecondaryText
                                : AppTheme.lightSecondaryText),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        folder.name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected
                              ? FontWeight.w500
                              : FontWeight.w400,
                          color: isSelected
                              ? AppTheme.primaryColor
                              : (isDark
                                    ? AppTheme.darkOnSurface
                                    : AppTheme.lightOnSurface),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isSelected)
                      PopupMenuButton<String>(
                        icon: Icon(
                          Icons.more_horiz,
                          size: 14,
                          color: AppTheme.primaryColor,
                        ),
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'rename',
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 14),
                                SizedBox(width: 8),
                                Text('Rename'),
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
                          if (value == 'rename') {
                            _showRenameFolderDialog(context, folder);
                          } else if (value == 'delete') {
                            _showDeleteFolderDialog(context, folder);
                          }
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (hasSubFolders)
          ...subFolders.map(
            (subFolder) => _buildFolderItem(
              context,
              subFolder,
              folderProvider,
              isDark,
              depth + 1,
            ),
          ),
      ],
    );
  }

  Widget _buildFooter(BuildContext context, bool isDark) {
    if (widget.isCollapsed) {
      return Container(
        height: 60,
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            IconButton(
              onPressed: () => context.read<ThemeProvider>().toggleTheme(),
              icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode, size: 18),
              style: IconButton.styleFrom(
                foregroundColor: isDark
                    ? AppTheme.darkSecondaryText
                    : AppTheme.lightSecondaryText,
              ),
            ),
          ],
        ),
      );
    }

    return FadeTransition(
      opacity: _opacityAnimation,
      child: Container(
        height: 60,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Settings',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? AppTheme.darkSecondaryText
                      : AppTheme.lightSecondaryText,
                ),
              ),
            ),
            IconButton(
              onPressed: () => context.read<ThemeProvider>().toggleTheme(),
              icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode, size: 18),
              style: IconButton.styleFrom(
                foregroundColor: isDark
                    ? AppTheme.darkSecondaryText
                    : AppTheme.lightSecondaryText,
                minimumSize: const Size(32, 32),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _createNewNote(BuildContext context) {
    final folderProvider = context.read<FolderProvider>();
    if (folderProvider.selectedFolder == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a folder first')),
      );
      return;
    }
    // This would typically navigate to note creation or trigger note creation
  }

  void _showCreateFolderDialog(BuildContext context) {
    // Implementation for creating folder dialog
  }

  void _showRenameFolderDialog(BuildContext context, Folder folder) {
    // Implementation for renaming folder dialog
  }

  void _showDeleteFolderDialog(BuildContext context, Folder folder) {
    // Implementation for deleting folder dialog
  }
}
