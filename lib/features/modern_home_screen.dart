import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/note_provider.dart';
import '../providers/folder_provider.dart';
import '../core/theme/app_theme.dart';
import '../widgets/common/modern_sidebar.dart';
import '../widgets/common/modern_notes_list.dart';
import '../widgets/common/modern_note_editor.dart';

class ModernHomeScreen extends StatefulWidget {
  const ModernHomeScreen({super.key});

  @override
  State<ModernHomeScreen> createState() => _ModernHomeScreenState();
}

class _ModernHomeScreenState extends State<ModernHomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isMobile = false;
  bool _isTablet = false;
  bool _showNotesList = true;
  bool _isSidebarCollapsed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    _isMobile = size.width < 768;
    _isTablet = size.width >= 768 && size.width < 1024;

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDark = themeProvider.isDarkMode;

        return Scaffold(
          backgroundColor: isDark
              ? AppTheme.darkBackground
              : AppTheme.lightBackground,
          body: FadeTransition(
            opacity: _fadeAnimation,
            child: _buildResponsiveLayout(context, isDark),
          ),
        );
      },
    );
  }

  Widget _buildResponsiveLayout(BuildContext context, bool isDark) {
    if (_isMobile) {
      return _buildMobileLayout(context, isDark);
    } else if (_isTablet) {
      return _buildTabletLayout(context, isDark);
    } else {
      return _buildDesktopLayout(context, isDark);
    }
  }

  Widget _buildMobileLayout(BuildContext context, bool isDark) {
    return Stack(
      children: [
        // Main content with navigation
        _buildMobileContent(context, isDark),

        // Floating action button for mobile
        Positioned(
          bottom: 20,
          right: 20,
          child: _buildMobileFAB(context, isDark),
        ),
      ],
    );
  }

  Widget _buildMobileContent(BuildContext context, bool isDark) {
    return PageView(
      children: [
        // Sidebar page
        ModernSidebar(isCollapsed: false, onToggle: () {}),

        // Notes list page
        const ModernNotesList(),

        // Editor page
        const ModernNoteEditor(),
      ],
    );
  }

  Widget _buildMobileFAB(BuildContext context, bool isDark) {
    return FloatingActionButton.extended(
      onPressed: () => _createNewNote(context),
      backgroundColor: AppTheme.primaryColor,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.add),
      label: const Text('New Note'),
    );
  }

  Widget _buildTabletLayout(BuildContext context, bool isDark) {
    return Row(
      children: [
        // Sidebar - collapsible
        SizedBox(
          width: _isSidebarCollapsed ? 80 : 280,
          child: ModernSidebar(
            isCollapsed: _isSidebarCollapsed,
            onToggle: () {
              setState(() {
                _isSidebarCollapsed = !_isSidebarCollapsed;
              });
            },
          ),
        ),

        // Divider
        Container(
          width: 1,
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
        ),

        // Main content area
        Expanded(
          child: _showNotesList
              ? Row(
                  children: [
                    // Notes list
                    const SizedBox(width: 320, child: ModernNotesList()),

                    // Divider
                    Container(
                      width: 1,
                      color: isDark
                          ? AppTheme.darkBorder
                          : AppTheme.lightBorder,
                    ),

                    // Note editor
                    const Expanded(child: ModernNoteEditor()),
                  ],
                )
              : const ModernNoteEditor(),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context, bool isDark) {
    return Row(
      children: [
        // Sidebar - always visible and wider on desktop
        SizedBox(
          width: _isSidebarCollapsed ? 80 : 300,
          child: ModernSidebar(
            isCollapsed: _isSidebarCollapsed,
            onToggle: () {
              setState(() {
                _isSidebarCollapsed = !_isSidebarCollapsed;
              });
            },
          ),
        ),

        // Divider
        Container(
          width: 1,
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
        ),

        // Notes list - resizable
        SizedBox(
          width: 360,
          child: Column(
            children: [
              _buildNotesListHeader(context, isDark),
              const Expanded(child: ModernNotesList()),
            ],
          ),
        ),

        // Divider
        Container(
          width: 1,
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
        ),

        // Note editor - takes remaining space
        const Expanded(child: ModernNoteEditor()),
      ],
    );
  }

  Widget _buildNotesListHeader(BuildContext context, bool isDark) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Notes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppTheme.darkOnSurface
                    : AppTheme.lightOnSurface,
              ),
            ),
          ),
          IconButton(
            onPressed: () => _createNewNote(context),
            icon: const Icon(Icons.add, size: 20),
            style: IconButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              minimumSize: const Size(36, 36),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
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
                value: 'sort_name',
                child: Row(
                  children: [
                    Icon(Icons.sort_by_alpha, size: 16),
                    SizedBox(width: 8),
                    Text('Sort by Name'),
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
              const PopupMenuItem(
                value: 'view_list',
                child: Row(
                  children: [
                    Icon(Icons.view_list, size: 16),
                    SizedBox(width: 8),
                    Text('List View'),
                  ],
                ),
              ),
            ],
            onSelected: (value) => _handleNotesAction(context, value),
          ),
        ],
      ),
    );
  }

  void _createNewNote(BuildContext context) {
    // Get the selected folder from the folder provider
    final folderProvider = context.read<FolderProvider>();
    final selectedFolderId = folderProvider.selectedFolder?.id ?? 'default';

    // Create new note
    final noteProvider = context.read<NoteProvider>();
    noteProvider.createNote(
      title: 'Untitled Note',
      content: '',
      folderId: selectedFolderId,
    );
  }

  void _handleNotesAction(BuildContext context, String action) {
    switch (action) {
      case 'sort_date':
        // Implement sorting by date - for now just show a message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Sort by date selected'),
            backgroundColor: AppTheme.accentColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
        break;
      case 'sort_name':
        // Implement sorting by name - for now just show a message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Sort by name selected'),
            backgroundColor: AppTheme.accentColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
        break;
      case 'view_grid':
        // Implement grid view - for now just show a message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Grid view selected'),
            backgroundColor: AppTheme.accentColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
        break;
      case 'view_list':
        // Implement list view - for now just show a message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('List view selected'),
            backgroundColor: AppTheme.accentColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
        break;
    }
  }
}

// Custom app bar for the modern interface
class ModernAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool isDark;
  final VoidCallback? onMenuPressed;
  final String title;

  const ModernAppBar({
    super.key,
    required this.isDark,
    this.onMenuPressed,
    this.title = 'Notive',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: preferredSize.height,
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              if (onMenuPressed != null)
                IconButton(
                  onPressed: onMenuPressed,
                  icon: const Icon(Icons.menu),
                  style: IconButton.styleFrom(
                    foregroundColor: isDark
                        ? AppTheme.darkOnSurface
                        : AppTheme.lightOnSurface,
                  ),
                ),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppTheme.darkOnSurface
                        : AppTheme.lightOnSurface,
                  ),
                ),
              ),
              Consumer<ThemeProvider>(
                builder: (context, themeProvider, child) {
                  return IconButton(
                    onPressed: () => themeProvider.toggleTheme(),
                    icon: Icon(
                      themeProvider.isDarkMode
                          ? Icons.light_mode
                          : Icons.dark_mode,
                    ),
                    style: IconButton.styleFrom(
                      foregroundColor: isDark
                          ? AppTheme.darkOnSurface
                          : AppTheme.lightOnSurface,
                    ),
                    tooltip: themeProvider.isDarkMode
                        ? 'Light Mode'
                        : 'Dark Mode',
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(60);
}

// Custom drawer for mobile
class ModernDrawer extends StatelessWidget {
  const ModernDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(child: ModernSidebar(isCollapsed: false, onToggle: () {}));
  }
}

// Navigation rail for tablet view
class ModernNavigationRail extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final bool isDark;

  const ModernNavigationRail({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        border: Border(
          right: BorderSide(
            color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
          ),
        ),
      ),
      child: NavigationRail(
        selectedIndex: selectedIndex,
        onDestinationSelected: onDestinationSelected,
        backgroundColor: Colors.transparent,
        selectedIconTheme: const IconThemeData(color: AppTheme.primaryColor),
        unselectedIconTheme: IconThemeData(
          color: isDark
              ? AppTheme.darkSecondaryText
              : AppTheme.lightSecondaryText,
        ),
        selectedLabelTextStyle: const TextStyle(
          color: AppTheme.primaryColor,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelTextStyle: TextStyle(
          color: isDark
              ? AppTheme.darkSecondaryText
              : AppTheme.lightSecondaryText,
        ),
        destinations: const [
          NavigationRailDestination(
            icon: Icon(Icons.folder_outlined),
            selectedIcon: Icon(Icons.folder),
            label: Text('Folders'),
          ),
          NavigationRailDestination(
            icon: Icon(Icons.note_outlined),
            selectedIcon: Icon(Icons.note),
            label: Text('Notes'),
          ),
          NavigationRailDestination(
            icon: Icon(Icons.edit_outlined),
            selectedIcon: Icon(Icons.edit),
            label: Text('Editor'),
          ),
        ],
      ),
    );
  }
}
