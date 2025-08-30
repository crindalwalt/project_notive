class AppConstants {
  static const String appName = 'Notive';
  static const String dbName = 'notive.db';
  static const int dbVersion = 1;

  // Table names
  static const String foldersTable = 'folders';
  static const String notesTable = 'notes';

  // Responsive breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1024;

  // Editor constants
  static const int autoSaveDelaySeconds = 2;
  static const int maxRecentNotes = 10;

  // Default folder names
  static const String defaultFolderName = 'General';
  static const String pinnedFolderName = 'Pinned';
}
