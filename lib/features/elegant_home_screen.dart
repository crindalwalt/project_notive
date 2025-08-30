import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/note_provider.dart';
import '../providers/folder_provider.dart';
import '../widgets/common/elegant_sidebar.dart';
import '../widgets/common/elegant_note_editor.dart';

class ElegantHomeScreen extends StatefulWidget {
  const ElegantHomeScreen({super.key});

  @override
  State<ElegantHomeScreen> createState() => _ElegantHomeScreenState();
}

class _ElegantHomeScreenState extends State<ElegantHomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isSidebarCollapsed = false;
  bool _isMobile = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animationController.forward();
    _loadInitialData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _loadInitialData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FolderProvider>().loadFolders();
      context.read<NoteProvider>().loadNotes();
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    _isMobile = size.width < 768;

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDark = themeProvider.isDarkMode;

        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          body: FadeTransition(
            opacity: _animationController,
            child: _isMobile ? _buildMobileLayout() : _buildDesktopLayout(),
          ),
        );
      },
    );
  }

  Widget _buildMobileLayout() {
    return _buildTwoPanel();
  }

  Widget _buildDesktopLayout() {
    return _buildTwoPanel();
  }

  Widget _buildTwoPanel() {
    return Row(
      children: [
        // Elegant Sidebar
        ElegantSidebar(
          isCollapsed: _isSidebarCollapsed,
          onToggleCollapse: () {
            setState(() {
              _isSidebarCollapsed = !_isSidebarCollapsed;
            });
          },
        ),

        // Note Editor
        const Expanded(child: ElegantNoteEditor()),
      ],
    );
  }
}

// Custom Material App wrapper to ensure proper theming
class ElegantNativeApp extends StatelessWidget {
  const ElegantNativeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => FolderProvider()),
        ChangeNotifierProvider(create: (context) => NoteProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Notive',
            debugShowCheckedModeBanner: false,
            theme: _buildLightTheme(),
            darkTheme: _buildDarkTheme(),
            themeMode: themeProvider.themeMode,
            home: const ElegantHomeScreen(),
          );
        },
      ),
    );
  }

  ThemeData _buildLightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme:
          ColorScheme.fromSeed(
            seedColor: const Color(0xFF007ACC),
            brightness: Brightness.light,
          ).copyWith(
            surface: Colors.white,
            surfaceContainerHighest: const Color(0xFFF8F9FA),
            outline: const Color(0xFFE5E7EB),
          ),
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(
          fontFamily: 'SF Pro Text',
          fontSize: 16,
          color: Color(0xFF374151),
        ),
        bodyMedium: TextStyle(
          fontFamily: 'SF Pro Text',
          fontSize: 14,
          color: Color(0xFF374151),
        ),
        titleLarge: TextStyle(
          fontFamily: 'SF Pro Display',
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1F2937),
        ),
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme:
          ColorScheme.fromSeed(
            seedColor: const Color(0xFF007ACC),
            brightness: Brightness.dark,
          ).copyWith(
            surface: const Color(0xFF1E1E1E),
            surfaceContainerHighest: const Color(0xFF252526),
            outline: const Color(0xFF2D2D30),
          ),
      scaffoldBackgroundColor: const Color(0xFF1E1E1E),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF252526),
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF252526),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Color(0xFF2D2D30)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFF252526),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: const Color(0xFF252526),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Color(0xFF2D2D30)),
        ),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(
          fontFamily: 'SF Pro Text',
          fontSize: 16,
          color: Color(0xFFCCCCCC),
        ),
        bodyMedium: TextStyle(
          fontFamily: 'SF Pro Text',
          fontSize: 14,
          color: Color(0xFFCCCCCC),
        ),
        titleLarge: TextStyle(
          fontFamily: 'SF Pro Display',
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: Color(0xFFCCCCCC),
        ),
      ),
    );
  }
}
