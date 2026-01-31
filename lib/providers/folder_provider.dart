import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/folder_model.dart';
import '../services/database_service.dart';

class FolderProvider extends ChangeNotifier {
  List<FolderModel> _folders = [];
  String? _selectedFolderId;

  List<FolderModel> get folders => _folders;
  String? get selectedFolderId => _selectedFolderId;

  FolderModel? get selectedFolder {
    if (_selectedFolderId == null) return null;
    try {
      return _folders.firstWhere((f) => f.id == _selectedFolderId);
    } catch (e) {
      return null;
    }
  }

  /// Load folders
  Future<void> loadFolders() async {
    _folders = DatabaseService.getAllFolders();
    notifyListeners();
  }

  /// Chọn folder
  void selectFolder(String? folderId) {
    _selectedFolderId = folderId;
    notifyListeners();
  }

  /// Tạo folder mới
  Future<FolderModel> createFolder(String name, {int colorIndex = 0}) async {
    final folder = FolderModel(
      id: const Uuid().v4(),
      name: name,
      colorIndex: colorIndex,
      createdAt: DateTime.now(),
      order: _folders.length,
    );

    await DatabaseService.saveFolder(folder);
    await loadFolders();
    return folder;
  }

  /// Cập nhật folder
  Future<void> updateFolder(String id, {String? name, int? colorIndex}) async {
    final index = _folders.indexWhere((f) => f.id == id);
    if (index < 0) return;

    final updated = _folders[index].copyWith(
      name: name,
      colorIndex: colorIndex,
    );

    await DatabaseService.saveFolder(updated);
    await loadFolders();
  }

  /// Xóa folder
  Future<void> deleteFolder(String id) async {
    await DatabaseService.deleteFolder(id);
    if (_selectedFolderId == id) {
      _selectedFolderId = null;
    }
    await loadFolders();
  }

  /// Sắp xếp lại folders
  Future<void> reorderFolders(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final folder = _folders.removeAt(oldIndex);
    _folders.insert(newIndex, folder);

    // Cập nhật order cho tất cả folders
    for (int i = 0; i < _folders.length; i++) {
      final updated = _folders[i].copyWith(order: i);
      await DatabaseService.saveFolder(updated);
    }

    notifyListeners();
  }
}
