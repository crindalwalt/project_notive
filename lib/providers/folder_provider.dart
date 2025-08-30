import 'package:flutter/material.dart';
import '../data/models/folder.dart';
import '../data/repositories/folder_repository.dart';

class FolderProvider with ChangeNotifier {
  final FolderRepository _repository = FolderRepository();

  List<Folder> _folders = [];
  Folder? _selectedFolder;
  bool _isLoading = false;
  String? _error;

  List<Folder> get folders => _folders;
  Folder? get selectedFolder => _selectedFolder;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<Folder> get rootFolders =>
      _folders.where((folder) => folder.parentId == null).toList();

  Future<void> loadFolders() async {
    try {
      _isLoading = true;
      // Don't notify listeners yet to avoid setState during build

      _folders = await _repository.getAllFolders();
      _error = null;

      // Set default folder as selected if none is selected
      if (_selectedFolder == null && _folders.isNotEmpty) {
        _selectedFolder = _folders.firstWhere(
          (folder) => folder.id == 'default',
          orElse: () => _folders.first,
        );
      }
    } catch (e) {
      _error = e.toString();
      print('Error loading folders: $e');
    } finally {
      _isLoading = false;
      notifyListeners(); // Only notify once at the end
    }
  }

  Future<void> createFolder(String name, {String? parentId}) async {
    try {
      await _repository.createFolder(name, parentId: parentId);
      await loadFolders();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateFolder(String id, {String? name, String? parentId}) async {
    try {
      await _repository.updateFolder(id, name: name, parentId: parentId);
      await loadFolders();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteFolder(String id) async {
    try {
      // Don't allow deleting the default folder
      if (id == 'default') {
        _error = 'Cannot delete the default folder';
        notifyListeners();
        return;
      }

      await _repository.deleteFolder(id);

      // If the deleted folder was selected, select default folder
      if (_selectedFolder?.id == id) {
        _selectedFolder = _folders.firstWhere(
          (folder) => folder.id == 'default',
          orElse: () => _folders.first,
        );
      }

      await loadFolders();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void selectFolder(Folder folder) {
    _selectedFolder = folder;
    notifyListeners();
  }

  void selectFolderById(String id) {
    final folder = _folders.firstWhere(
      (folder) => folder.id == id,
      orElse: () => _folders.first,
    );
    selectFolder(folder);
  }

  List<Folder> getSubFolders(String parentId) {
    return _folders.where((folder) => folder.parentId == parentId).toList();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
