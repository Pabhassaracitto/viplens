import 'package:hive_flutter/hive_flutter.dart';

import '../models/folder_model.dart'; // Thêm dòng này
import '../models/mindmap_model.dart';
import '../models/node_model.dart';

class DatabaseService {
  static const String _mindmapBoxName = 'mindmaps';
  static const String _settingsBoxName = 'settings';

  static late Box<MindMapModel> _mindmapBox;
  static late Box<dynamic> _settingsBox;
  static late Box<FolderModel> _folderBox;

  /// Khởi tạo database
  static Future<void> initialize() async {
    await Hive.initFlutter();

    // Đăng ký adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(NodeModelAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(MindMapModelAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(FolderModelAdapter());
    }

    // Mở các boxes
    _mindmapBox = await Hive.openBox<MindMapModel>(_mindmapBoxName);
    _settingsBox = await Hive.openBox(_settingsBoxName);
    _folderBox = await Hive.openBox<FolderModel>('folders');
  }

  // ==================== MINDMAP OPERATIONS ====================

  /// Lấy tất cả mindmaps
  static List<MindMapModel> getAllMindMaps() {
    return _mindmapBox.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  /// Lấy mindmap theo ID
  static MindMapModel? getMindMapById(String id) {
    try {
      return _mindmapBox.values.firstWhere((map) => map.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Lưu mindmap (tạo mới hoặc cập nhật)
  static Future<void> saveMindMap(MindMapModel mindmap) async {
    final index = _mindmapBox.values.toList().indexWhere(
          (m) => m.id == mindmap.id,
        );

    if (index >= 0) {
      await _mindmapBox.putAt(index, mindmap);
    } else {
      await _mindmapBox.add(mindmap);
    }
  }

  /// Xóa mindmap
  static Future<void> deleteMindMap(String id) async {
    final index = _mindmapBox.values.toList().indexWhere((m) => m.id == id);
    if (index >= 0) {
      await _mindmapBox.deleteAt(index);
    }
  }

  /// Tìm kiếm mindmaps theo từ khóa
  static List<MindMapModel> searchMindMaps(String query) {
    if (query.isEmpty) return getAllMindMaps();

    final lowerQuery = query.toLowerCase();
    return _mindmapBox.values.where((map) {
      // Tìm trong title
      if (map.title.toLowerCase().contains(lowerQuery)) return true;

      // Tìm trong description
      if (map.description?.toLowerCase().contains(lowerQuery) ?? false) {
        return true;
      }

      // Tìm trong nodes
      for (final node in map.nodes) {
        if (node.content.toLowerCase().contains(lowerQuery)) return true;
        if (node.paliText?.toLowerCase().contains(lowerQuery) ?? false) {
          return true;
        }
      }

      // Tìm trong tags
      for (final tag in map.tags) {
        if (tag.toLowerCase().contains(lowerQuery)) return true;
      }

      return false;
    }).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  // ==================== FLASHCARD OPERATIONS ====================

  /// Lấy tất cả flashcards cần ôn tập hôm nay
  static List<MapEntry<MindMapModel, NodeModel>> getAllDueFlashcards() {
    final result = <MapEntry<MindMapModel, NodeModel>>[];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (final map in _mindmapBox.values) {
      for (final node in map.nodes) {
        if (!node.isFlashcard || node.nextReviewDate == null) continue;

        final reviewDate = DateTime(
          node.nextReviewDate!.year,
          node.nextReviewDate!.month,
          node.nextReviewDate!.day,
        );

        if (reviewDate.compareTo(today) <= 0) {
          result.add(MapEntry(map, node));
        }
      }
    }

    return result;
  }

  /// Đếm tổng số flashcards cần ôn tập
  static int getTotalDueFlashcardCount() {
    return getAllDueFlashcards().length;
  }

  // ==================== SETTINGS OPERATIONS ====================

  /// Lấy setting
  static T? getSetting<T>(String key, {T? defaultValue}) {
    return _settingsBox.get(key, defaultValue: defaultValue) as T?;
  }

  /// Lưu setting
  static Future<void> saveSetting<T>(String key, T value) async {
    await _settingsBox.put(key, value);
  }

  /// Kiểm tra dark mode
  static bool get isDarkMode {
    return getSetting<bool>('isDarkMode', defaultValue: false) ?? false;
  }

  /// Đặt dark mode
  static Future<void> setDarkMode(bool value) async {
    await saveSetting('isDarkMode', value);
  }

  /// Kiểm tra Zen mode mặc định
  static bool get defaultZenMode {
    return getSetting<bool>('defaultZenMode', defaultValue: false) ?? false;
  }

  // ==================== BACKUP/RESTORE ====================

  /// Export tất cả data thành JSON
  static Map<String, dynamic> exportAllData() {
    final mindmaps = getAllMindMaps();
    return {
      'version': '1.0.0',
      'exportedAt': DateTime.now().toIso8601String(),
      'mindmaps': mindmaps.map((m) => m.toJson()).toList(),
      'settings': _settingsBox.toMap(),
    };
  }

  /// Import data từ JSON
  static Future<int> importData(Map<String, dynamic> data) async {
    int importedCount = 0;

    if (data['mindmaps'] != null) {
      final mindmaps = data['mindmaps'] as List;
      for (final mapJson in mindmaps) {
        try {
          final mindmap = MindMapModel.fromJson(
            mapJson as Map<String, dynamic>,
          );
          await saveMindMap(mindmap);
          importedCount++;
        } catch (e) {
          print('Error importing mindmap: $e');
        }
      }
    }

    return importedCount;
  }

  /// Xóa tất cả data
  static Future<void> clearAllData() async {
    await _mindmapBox.clear();
  }
  // ==================== FOLDER OPERATIONS ====================

  /// Lấy tất cả folders
  static List<FolderModel> getAllFolders() {
    return _folderBox.values.toList()
      ..sort((a, b) => a.order.compareTo(b.order));
  }

  /// Lưu folder
  static Future<void> saveFolder(FolderModel folder) async {
    final index = _folderBox.values.toList().indexWhere(
          (f) => f.id == folder.id,
        );
    if (index >= 0) {
      await _folderBox.putAt(index, folder);
    } else {
      await _folderBox.add(folder);
    }
  }

  /// Xóa folder
  static Future<void> deleteFolder(String id) async {
    final index = _folderBox.values.toList().indexWhere((f) => f.id == id);
    if (index >= 0) {
      await _folderBox.deleteAt(index);
    }

    // Cập nhật các mindmap trong folder này
    final mindmaps = getAllMindMaps().where((m) => m.folderId == id);
    for (final m in mindmaps) {
      await saveMindMap(m.copyWith(folderId: null));
    }
  }

  /// Lấy mindmaps trong folder
  static List<MindMapModel> getMindMapsInFolder(String? folderId) {
    return getAllMindMaps().where((m) => m.folderId == folderId).toList();
  }

  /// Đếm mindmaps trong folder
  static int getMindMapCountInFolder(String? folderId) {
    return getAllMindMaps().where((m) => m.folderId == folderId).length;
  }
}
