import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import '../models/mindmap_model.dart';
import 'database_service.dart';
import 'text_parser_service.dart';

class ImportResult {
  final bool success;
  final String message;
  final int importedCount;
  final List<String> errors;

  ImportResult({
    required this.success,
    required this.message,
    this.importedCount = 0,
    this.errors = const [],
  });
}

class ImportService {
  /// Chọn và import file
  static Future<ImportResult> pickAndImport() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json', 'md', 'txt'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        return ImportResult(success: false, message: 'Không có file được chọn');
      }

      final file = File(result.files.single.path!);
      final content = await file.readAsString();
      final extension = result.files.single.extension?.toLowerCase();

      switch (extension) {
        case 'json':
          return await importFromJson(content);
        case 'md':
          return await importFromMarkdown(content);
        case 'txt':
          return await importFromText(content);
        default:
          return ImportResult(
            success: false,
            message: 'Định dạng file không được hỗ trợ',
          );
      }
    } catch (e) {
      return ImportResult(success: false, message: 'Lỗi khi import: $e');
    }
  }

  /// Import từ JSON
  static Future<ImportResult> importFromJson(String content) async {
    try {
      final json = jsonDecode(content) as Map<String, dynamic>;

      // Kiểm tra xem đây là backup hay single mindmap
      if (json.containsKey('mindmaps')) {
        // Đây là backup file
        final count = await DatabaseService.importData(json);
        return ImportResult(
          success: true,
          message: 'Đã import $count sơ đồ từ backup',
          importedCount: count,
        );
      } else if (json.containsKey('id') && json.containsKey('nodes')) {
        // Đây là single mindmap
        final mindmap = MindMapModel.fromJson(json);
        await DatabaseService.saveMindMap(mindmap);
        return ImportResult(
          success: true,
          message: 'Đã import sơ đồ "${mindmap.title}"',
          importedCount: 1,
        );
      } else {
        return ImportResult(
          success: false,
          message: 'File JSON không đúng định dạng',
        );
      }
    } catch (e) {
      return ImportResult(success: false, message: 'Lỗi khi đọc file JSON: $e');
    }
  }

  /// Import từ Markdown
  static Future<ImportResult> importFromMarkdown(String content) async {
    try {
      final lines = content.split('\n');
      String title = 'Imported Mindmap';
      final contentLines = <String>[];

      for (final line in lines) {
        if (line.startsWith('# ')) {
          title = line.substring(2).trim();
        } else if (line.startsWith('- ') || line.startsWith('  ')) {
          // Convert markdown list to our format
          contentLines.add(line);
        }
      }

      final mindmap = TextParserService.parseTextToMindMap(
        contentLines.join('\n'),
        title,
      );

      await DatabaseService.saveMindMap(mindmap);

      return ImportResult(
        success: true,
        message: 'Đã import sơ đồ "$title"',
        importedCount: 1,
      );
    } catch (e) {
      return ImportResult(
        success: false,
        message: 'Lỗi khi đọc file Markdown: $e',
      );
    }
  }

  /// Import từ plain text
  static Future<ImportResult> importFromText(String content) async {
    try {
      final lines = content.split('\n');
      String title = 'Imported Mindmap';

      // Dòng đầu tiên là title
      if (lines.isNotEmpty) {
        title = lines.first.trim();
        if (title.isEmpty && lines.length > 1) {
          title = lines[1].trim();
        }
      }

      final mindmap = TextParserService.parseTextToMindMap(content, title);
      await DatabaseService.saveMindMap(mindmap);

      return ImportResult(
        success: true,
        message: 'Đã import sơ đồ "$title"',
        importedCount: 1,
      );
    } catch (e) {
      return ImportResult(success: false, message: 'Lỗi khi đọc file: $e');
    }
  }
}
