# Notive - Cross-Platform Note Taking App

A beautiful, cross-platform note-taking application built with Flutter that works seamlessly on Android, iOS, Web, Windows, and Linux.

## 🌟 Features

### Core Features (Version 1)
- **Rich Text Editing**: Create and edit notes with basic markdown formatting
  - Bold, italic formatting
  - Bullet and numbered lists
  - Quotes
  - Live character count
- **Folder Organization**: Create folders and organize notes
- **Note Management**: Create, update, delete, and pin notes
- **Offline Storage**: All data stored locally using SQLite
- **Search**: Search notes by title and content
- **Auto-save**: Notes are automatically saved as you type
- **Responsive Design**: Adapts to different screen sizes and platforms

### Responsive Layouts
- **Mobile (< 600px)**: Bottom navigation with fullscreen editor
- **Tablet (600-1024px)**: Two-pane layout with sidebar
- **Desktop (> 1024px)**: Three-pane layout (folders | notes | editor)

### Theme Support
- Light and Dark mode support
- Automatic system theme detection
- Material 3 design

## 🏗️ Architecture

The app follows a clean architecture pattern with:

```
lib/
├── core/
│   ├── theme/           # App theming
│   └── utils/           # Utilities and constants
├── data/
│   ├── database/        # SQLite database layer
│   ├── models/          # Data models
│   └── repositories/    # Data repositories
├── features/
│   ├── folders/         # Folder management UI
│   ├── notes/           # Note management UI
│   └── settings/        # App settings
├── providers/           # State management (Provider pattern)
└── widgets/
    └── common/          # Reusable widgets
```

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.32.6 or later)
- Dart SDK (3.8.1 or later)

### Installation

1. Clone the repository:
```bash
git clone https://github.com/crindalwalt/project_notive.git
cd project_notive
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
# For desktop (Linux/Windows/macOS)
flutter run -d linux
flutter run -d windows
flutter run -d macos

# For mobile
flutter run -d android
flutter run -d ios

# For web
flutter run -d chrome
```

## 📱 Platform Support

- ✅ **Android**: Full support
- ✅ **iOS**: Full support  
- ✅ **Web**: Full support
- ✅ **Windows**: Full support
- ✅ **Linux**: Full support
- ✅ **macOS**: Full support

## 🗄️ Database Schema

### Folders Table
```sql
CREATE TABLE folders (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  parent_id TEXT,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);
```

### Notes Table
```sql
CREATE TABLE notes (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  folder_id TEXT NOT NULL,
  is_pinned INTEGER DEFAULT 0,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);
```

## 🎯 State Management

The app uses the Provider pattern for state management with the following providers:

- **FolderProvider**: Manages folder operations and state
- **NoteProvider**: Manages note operations and state  
- **ThemeProvider**: Manages app theme state

## 🔧 Key Dependencies

- `provider`: State management
- `sqflite`: SQLite database for mobile
- `sqflite_common_ffi`: SQLite for desktop platforms
- `path_provider`: File system access
- `uuid`: UUID generation

## 🛣️ Roadmap

### Future Features (Post v1)
- **Cloud Sync**: Firebase/Supabase integration for cross-device sync
- **Real-time Collaboration**: Multi-user live editing
- **Export/Import**: Markdown, PDF, HTML export
- **Encryption**: Local password protection
- **Reminders**: Note reminders and notifications
- **Tags**: Advanced tagging system
- **Full-text Search**: Enhanced search with indexing
- **Rich Text Editor**: Advanced formatting with a proper rich text editor

## 🐛 Known Issues

- Rich text editing is currently basic (markdown-style)
- No cloud sync in v1 (offline only)
- Limited formatting options compared to full-featured editors

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🔥 Performance

- Lazy loading for large note collections
- Efficient SQLite queries with proper indexing
- Auto-save with debouncing to prevent excessive writes
- Responsive UI that adapts to different screen sizes

## 📞 Support

For support, please create an issue in the GitHub repository.
