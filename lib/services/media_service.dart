import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

class MediaService {
  static final ImagePicker _picker = ImagePicker();
  static const _uuid = Uuid();

  /// Lấy thư mục lưu trữ media
  static Future<Directory> getMediaDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final mediaDir = Directory('${appDir.path}/media');
    if (!await mediaDir.exists()) {
      await mediaDir.create(recursive: true);
    }
    return mediaDir;
  }

  /// Lấy thư mục lưu trữ hình ảnh
  static Future<Directory> getImagesDirectory() async {
    final mediaDir = await getMediaDirectory();
    final imagesDir = Directory('${mediaDir.path}/images');
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }
    return imagesDir;
  }

  /// Lấy thư mục lưu trữ audio
  static Future<Directory> getAudioDirectory() async {
    final mediaDir = await getMediaDirectory();
    final audioDir = Directory('${mediaDir.path}/audio');
    if (!await audioDir.exists()) {
      await audioDir.create(recursive: true);
    }
    return audioDir;
  }

  /// Chọn hình ảnh từ gallery
  static Future<String?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image == null) return null;

      return await _saveImage(File(image.path));
    } catch (e) {
      debugPrint('Error picking image from gallery: $e');
      return null;
    }
  }

  /// Chụp ảnh từ camera
  static Future<String?> pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image == null) return null;

      return await _saveImage(File(image.path));
    } catch (e) {
      debugPrint('Error picking image from camera: $e');
      return null;
    }
  }

  /// Lưu hình ảnh vào thư mục app
  static Future<String> _saveImage(File imageFile) async {
    final imagesDir = await getImagesDirectory();
    final extension = path.extension(imageFile.path);
    final fileName = '${_uuid.v4()}$extension';
    final savedFile = await imageFile.copy('${imagesDir.path}/$fileName');
    return savedFile.path;
  }

  /// Xóa hình ảnh
  static Future<void> deleteImage(String imagePath) async {
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('Error deleting image: $e');
    }
  }

  /// Xóa audio
  static Future<void> deleteAudio(String audioPath) async {
    try {
      final file = File(audioPath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('Error deleting audio: $e');
    }
  }

  /// Lấy kích thước file
  static Future<String> getFileSize(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return '0 B';

      final bytes = await file.length();
      if (bytes < 1024) return '$bytes B';
      if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } catch (e) {
      return '0 B';
    }
  }

  /// Tính tổng dung lượng media
  static Future<String> getTotalMediaSize() async {
    try {
      final mediaDir = await getMediaDirectory();
      if (!await mediaDir.exists()) return '0 B';

      int totalBytes = 0;
      await for (final entity in mediaDir.list(recursive: true)) {
        if (entity is File) {
          totalBytes += await entity.length();
        }
      }

      if (totalBytes < 1024) return '$totalBytes B';
      if (totalBytes < 1024 * 1024) {
        return '${(totalBytes / 1024).toStringAsFixed(1)} KB';
      }
      if (totalBytes < 1024 * 1024 * 1024) {
        return '${(totalBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
      }
      return '${(totalBytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    } catch (e) {
      return '0 B';
    }
  }

  /// Xóa tất cả media không sử dụng
  static Future<int> cleanupUnusedMedia(Set<String> usedPaths) async {
    int deletedCount = 0;
    try {
      final mediaDir = await getMediaDirectory();
      if (!await mediaDir.exists()) return 0;

      await for (final entity in mediaDir.list(recursive: true)) {
        if (entity is File) {
          if (!usedPaths.contains(entity.path)) {
            await entity.delete();
            deletedCount++;
          }
        }
      }
    } catch (e) {
      debugPrint('Error cleaning up media: $e');
    }
    return deletedCount;
  }
}
