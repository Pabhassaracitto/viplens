import 'dart:convert';

import '../models/folder_model.dart';
import '../models/mindmap_model.dart';

/// Decoder/encoder for versioned Viplens backup files.
class BackupCodec {
  static const formatName = 'viplens_backup';
  static const currentSchemaVersion = 1;

  static Map<String, dynamic> encode({
    required List<MindMapModel> mindmaps,
    required List<FolderModel> folders,
    required Map<String, dynamic> settings,
    DateTime? exportedAt,
  }) {
    return {
      'format': formatName,
      'schemaVersion': currentSchemaVersion,
      'exportedAt': (exportedAt ?? DateTime.now()).toIso8601String(),
      'mindmaps': mindmaps.map((mindmap) => mindmap.toJson()).toList(),
      'folders': folders.map((folder) => folder.toJson()).toList(),
      'settings': settings,
    };
  }

  /// Validates the entire backup before any caller mutates persistent data.
  /// Backups produced by the older app (version + mindmaps, no schemaVersion)
  /// remain importable as a merge.
  static BackupData decode(Map<String, dynamic> json) {
    final isCurrent = json['format'] == formatName;
    final isLegacy = !json.containsKey('schemaVersion') &&
        json['version'] is String &&
        json['mindmaps'] is List;

    if (!isCurrent && !isLegacy) {
      throw const FormatException('File không phải backup Viplens hợp lệ.');
    }
    if (isCurrent && json['schemaVersion'] != currentSchemaVersion) {
      throw FormatException(
        'Phiên bản backup không được hỗ trợ: ${json['schemaVersion']}.',
      );
    }

    final rawMindmaps = json['mindmaps'];
    final rawFolders = json['folders'] ?? const <dynamic>[];
    final rawSettings = json['settings'] ?? const <String, dynamic>{};
    if (rawMindmaps is! List || rawFolders is! List || rawSettings is! Map) {
      throw const FormatException('Cấu trúc backup không hợp lệ.');
    }

    try {
      final mindmaps = rawMindmaps.map((value) {
        if (value is! Map) {
          throw const FormatException('Mindmap trong backup không hợp lệ.');
        }
        final mindmap = MindMapModel.fromJson(Map<String, dynamic>.from(value));
        final nodeIds = mindmap.nodes.map((node) => node.id).toSet();
        if (nodeIds.length != mindmap.nodes.length ||
            !nodeIds.contains(mindmap.rootNodeId)) {
          throw const FormatException('Cấu trúc node của mindmap không hợp lệ.');
        }
        for (final node in mindmap.nodes) {
          if (node.childIds.any((id) => !nodeIds.contains(id))) {
            throw const FormatException('Mindmap tham chiếu node không tồn tại.');
          }
        }
        return mindmap;
      }).toList();

      final mindmapIds = mindmaps.map((mindmap) => mindmap.id).toSet();
      if (mindmapIds.length != mindmaps.length) {
        throw const FormatException('Backup chứa mindmap trùng ID.');
      }

      final folders = rawFolders.map((value) {
        if (value is! Map) {
          throw const FormatException('Thư mục trong backup không hợp lệ.');
        }
        return FolderModel.fromJson(Map<String, dynamic>.from(value));
      }).toList();
      if (folders.map((folder) => folder.id).toSet().length != folders.length) {
        throw const FormatException('Backup chứa thư mục trùng ID.');
      }

      final settings = Map<String, dynamic>.from(rawSettings);
      // Ensure setting values can be represented by a JSON backup.
      jsonEncode(settings);

      return BackupData(
        mindmaps: mindmaps,
        folders: folders,
        settings: settings,
      );
    } on FormatException {
      rethrow;
    } catch (error) {
      throw FormatException('Dữ liệu backup bị lỗi: $error');
    }
  }
}

class BackupData {
  final List<MindMapModel> mindmaps;
  final List<FolderModel> folders;
  final Map<String, dynamic> settings;

  const BackupData({
    required this.mindmaps,
    required this.folders,
    required this.settings,
  });
}
