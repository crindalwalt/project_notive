import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/folder.dart';
import 'package:uuid/uuid.dart';

class FolderRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final Uuid _uuid = const Uuid();

  Future<List<Folder>> getAllFolders() async {
    return await _databaseHelper.getAllFolders();
  }

  Future<Folder?> getFolderById(String id) async {
    return await _databaseHelper.getFolderById(id);
  }

  Future<String> createFolder(String name, {String? parentId}) async {
    final folder = Folder(
      id: _uuid.v4(),
      name: name,
      parentId: parentId,
      emoji: '📁',
      color: const Color(0xFF007ACC),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    return await _databaseHelper.insertFolder(folder);
  }

  Future<String> createFolderWithStyle(
    String name, {
    String? parentId,
    String emoji = '📁',
    Color color = const Color(0xFF007ACC),
  }) async {
    final folder = Folder(
      id: _uuid.v4(),
      name: name,
      parentId: parentId,
      emoji: emoji,
      color: color,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    return await _databaseHelper.insertFolder(folder);
  }

  Future<void> updateFolder(
    String id, {
    String? name,
    String? parentId,
    String? emoji,
    Color? color,
  }) async {
    final existingFolder = await _databaseHelper.getFolderById(id);
    if (existingFolder != null) {
      final updatedFolder = existingFolder.copyWith(
        name: name,
        parentId: parentId,
        emoji: emoji,
        color: color,
        updatedAt: DateTime.now(),
      );
      await _databaseHelper.updateFolder(updatedFolder);
    }
  }

  Future<void> deleteFolder(String id) async {
    await _databaseHelper.deleteFolder(id);
  }

  Future<List<Folder>> getSubFolders(String parentId) async {
    final allFolders = await getAllFolders();
    return allFolders.where((folder) => folder.parentId == parentId).toList();
  }

  Future<List<Folder>> getRootFolders() async {
    final allFolders = await getAllFolders();
    return allFolders.where((folder) => folder.parentId == null).toList();
  }
}
