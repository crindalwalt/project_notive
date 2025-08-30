import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/utils/helpers.dart';
import '../core/theme/app_theme.dart';
import '../providers/folder_provider.dart';
import '../providers/note_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/common/collapsible_sidebar.dart';
import 'folders/folder_list.dart';
import 'notes/note_list.dart';
import 'notes/note_editor.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _sidebarExpanded = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() async {
    final folderProvider = context.read<FolderProvider>();
    final noteProvider = context.read<NoteProvider>();

    await folderProvider.loadFolders();
    if (folderProvider.selectedFolder != null) {
      await noteProvider.loadNotesByFolder(folderProvider.selectedFolder!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;

        if (DeviceHelper.isMobile(screenWidth)) {
          return _buildMobileLayout();
        } else if (DeviceHelper.isTablet(screenWidth)) {
          return _buildTabletLayout();
        } else {
          return _buildDesktopLayout();
        }
      },
    );
  }

  Widget _buildMobileLayout() {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Notive'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.folder), text: 'Folders'),
              Tab(icon: Icon(Icons.note), text: 'Notes'),
            ],
          ),
          actions: [
            IconButton(
              onPressed: () => context.read<ThemeProvider>().toggleTheme(),
              icon: Icon(
                context.watch<ThemeProvider>().isDarkMode
                    ? Icons.light_mode
                    : Icons.dark_mode,
              ),
            ),
          ],
        ),
        body: const TabBarView(children: [FolderList(), NoteList()]),
        floatingActionButton: FloatingActionButton(
          onPressed: _createNewNote,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildTabletLayout() {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Row(
        children: [
          SizedBox(
            width: 300,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppTheme.darkSidebarBackground
                    : AppTheme.lightSidebarBackground,
                border: Border(
                  right: BorderSide(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppTheme.darkBorder
                        : AppTheme.lightBorder,
                  ),
                ),
              ),
              child: const FolderList(),
            ),
          ),
          const Expanded(child: NoteList()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewNote,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Scaffold(
      body: Row(
        children: [
          // Collapsible Sidebar
          CollapsibleSidebar(
            title: 'Notive',
            initiallyExpanded: _sidebarExpanded,
            onToggle: () =>
                setState(() => _sidebarExpanded = !_sidebarExpanded),
            child: const FolderList(),
          ),
          // Notes List
          SizedBox(
            width: 350,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                border: Border(
                  right: BorderSide(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppTheme.darkBorder
                        : AppTheme.lightBorder,
                  ),
                ),
              ),
              child: Column(
                children: [
                  _buildNotesHeader(),
                  const Expanded(child: NoteList()),
                ],
              ),
            ),
          ),
          // Note Editor
          const Expanded(child: NoteEditor()),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Notive'),
      actions: [
        IconButton(
          onPressed: () => context.read<ThemeProvider>().toggleTheme(),
          icon: Icon(
            context.watch<ThemeProvider>().isDarkMode
                ? Icons.light_mode
                : Icons.dark_mode,
          ),
        ),
      ],
    );
  }

  Widget _buildNotesHeader() {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppTheme.darkBorder
                : AppTheme.lightBorder,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Consumer<FolderProvider>(
              builder: (context, folderProvider, child) {
                return Text(
                  folderProvider.selectedFolder?.name ?? 'Notes',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                );
              },
            ),
          ),
          IconButton(
            onPressed: _createNewNote,
            icon: const Icon(Icons.add, size: 18),
            iconSize: 18,
            splashRadius: 16,
            tooltip: 'New note',
          ),
          IconButton(
            onPressed: () => context.read<ThemeProvider>().toggleTheme(),
            icon: Icon(
              context.watch<ThemeProvider>().isDarkMode
                  ? Icons.light_mode
                  : Icons.dark_mode,
              size: 18,
            ),
            iconSize: 18,
            splashRadius: 16,
            tooltip: 'Toggle theme',
          ),
        ],
      ),
    );
  }

  void _createNewNote() async {
    final folderProvider = context.read<FolderProvider>();
    final noteProvider = context.read<NoteProvider>();

    if (folderProvider.selectedFolder == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a folder first')),
      );
      return;
    }

    try {
      await noteProvider.createNote(
        title: 'Untitled Note',
        content: '',
        folderId: folderProvider.selectedFolder!.id,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error creating note: $e')));
      }
    }
  }
}
