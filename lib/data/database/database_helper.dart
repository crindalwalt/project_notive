import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../models/folder.dart';
import '../models/note.dart';
import '../../core/utils/constants.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  factory DatabaseHelper() {
    return _instance;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    try {
      // Initialize FFI for desktop platforms
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
      }

      String path;
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        final appDir = await getApplicationDocumentsDirectory();
        path = join(appDir.path, 'notive', AppConstants.dbName);

        // Create directory if it doesn't exist
        final dir = Directory(dirname(path));
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }
      } else {
        final dbDir = await getDatabasesPath();
        path = join(dbDir, AppConstants.dbName);
      }

      return await openDatabase(
        path,
        version: AppConstants.dbVersion,
        onCreate: _createTables,
        onUpgrade: _upgradeDatabase,
      );
    } catch (e) {
      try {
        // First fallback: try in-memory database
        print('Database initialization failed, trying in-memory database: $e');
        return await openDatabase(
          ':memory:',
          version: AppConstants.dbVersion,
          onCreate: _createTables,
          onUpgrade: _upgradeDatabase,
        );
      } catch (memoryError) {
        // Last resort: create a mock database with basic functionality
        print(
          'In-memory database also failed, using mock implementation: $memoryError',
        );
        return await _createMockDatabase();
      }
    }
  }

  Future<Database> _createMockDatabase() async {
    // This creates an in-memory database with minimal error handling
    try {
      sqfliteFfiInit();
      return await databaseFactoryFfi.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: AppConstants.dbVersion,
          onCreate: _createTables,
          onUpgrade: _upgradeDatabase,
        ),
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _createTables(Database db, int version) async {
    // Create folders table
    await db.execute('''
      CREATE TABLE ${AppConstants.foldersTable} (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        parent_id TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY (parent_id) REFERENCES ${AppConstants.foldersTable} (id) ON DELETE CASCADE
      )
    ''');

    // Create notes table
    await db.execute('''
      CREATE TABLE ${AppConstants.notesTable} (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        folder_id TEXT NOT NULL,
        is_pinned INTEGER DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY (folder_id) REFERENCES ${AppConstants.foldersTable} (id) ON DELETE CASCADE
      )
    ''');

    // Create indexes for better performance
    await db.execute(
      'CREATE INDEX idx_notes_folder_id ON ${AppConstants.notesTable} (folder_id)',
    );
    await db.execute(
      'CREATE INDEX idx_notes_updated_at ON ${AppConstants.notesTable} (updated_at DESC)',
    );
    await db.execute(
      'CREATE INDEX idx_folders_parent_id ON ${AppConstants.foldersTable} (parent_id)',
    );

    // Insert default folder
    final defaultFolder = Folder(
      id: 'default',
      name: AppConstants.defaultFolderName,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await db.insert(AppConstants.foldersTable, defaultFolder.toMap());
  }

  Future<void> _upgradeDatabase(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    // Handle database upgrades here
    if (oldVersion < 2) {
      // Add any future schema changes
    }
  }

  // Folder operations
  Future<String> insertFolder(Folder folder) async {
    final db = await database;
    await db.insert(AppConstants.foldersTable, folder.toMap());
    return folder.id;
  }

  Future<List<Folder>> getAllFolders() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.foldersTable,
      orderBy: 'name ASC',
    );
    return List.generate(maps.length, (i) => Folder.fromMap(maps[i]));
  }

  Future<Folder?> getFolderById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.foldersTable,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Folder.fromMap(maps.first);
    }
    return null;
  }

  Future<void> updateFolder(Folder folder) async {
    final db = await database;
    await db.update(
      AppConstants.foldersTable,
      folder.toMap(),
      where: 'id = ?',
      whereArgs: [folder.id],
    );
  }

  Future<void> deleteFolder(String id) async {
    final db = await database;
    await db.delete(
      AppConstants.foldersTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Note operations
  Future<String> insertNote(Note note) async {
    final db = await database;
    await db.insert(AppConstants.notesTable, note.toMap());
    return note.id;
  }

  Future<List<Note>> getAllNotes() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.notesTable,
      orderBy: 'updated_at DESC',
    );
    return List.generate(maps.length, (i) => Note.fromMap(maps[i]));
  }

  Future<List<Note>> getNotesByFolder(String folderId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.notesTable,
      where: 'folder_id = ?',
      whereArgs: [folderId],
      orderBy: 'updated_at DESC',
    );
    return List.generate(maps.length, (i) => Note.fromMap(maps[i]));
  }

  Future<List<Note>> getPinnedNotes() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.notesTable,
      where: 'is_pinned = ?',
      whereArgs: [1],
      orderBy: 'updated_at DESC',
    );
    return List.generate(maps.length, (i) => Note.fromMap(maps[i]));
  }

  Future<Note?> getNoteById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.notesTable,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Note.fromMap(maps.first);
    }
    return null;
  }

  Future<void> updateNote(Note note) async {
    final db = await database;
    await db.update(
      AppConstants.notesTable,
      note.toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  Future<void> deleteNote(String id) async {
    final db = await database;
    await db.delete(AppConstants.notesTable, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Note>> searchNotes(String query) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.notesTable,
      where: 'title LIKE ? OR content LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'updated_at DESC',
    );
    return List.generate(maps.length, (i) => Note.fromMap(maps[i]));
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
