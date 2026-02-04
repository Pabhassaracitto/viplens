import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

class ScreenshotService {
  static const _uuid = Uuid();

  /// Capture widget thành hình ảnh
  static Future<Uint8List?> captureWidget(GlobalKey key) async {
    try {
      final boundary =
          key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error capturing widget: $e');
      return null;
    }
  }

  /// Capture và lưu thành file
  static Future<String?> captureAndSave(GlobalKey key, String filename) async {
    try {
      final bytes = await captureWidget(key);
      if (bytes == null) return null;

      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/$filename.png');
      await file.writeAsBytes(bytes);

      return file.path;
    } catch (e) {
      debugPrint('Error saving screenshot: $e');
      return null;
    }
  }

  /// Capture và chia sẻ
  static Future<bool> captureAndShare(
    GlobalKey key, {
    String? title,
    String? text,
  }) async {
    try {
      final bytes = await captureWidget(key);
      if (bytes == null) return false;

      final directory = await getTemporaryDirectory();
      final filename = '${_uuid.v4()}.png';
      final file = File('${directory.path}/$filename');
      await file.writeAsBytes(bytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: title,
        text: text,
      );

      return true;
    } catch (e) {
      debugPrint('Error sharing screenshot: $e');
      return false;
    }
  }

  /// Capture mindmap với custom background
  static Future<Uint8List?> captureMindmapWithBackground(
    GlobalKey key, {
    Color backgroundColor = Colors.white,
    EdgeInsets padding = const EdgeInsets.all(40),
  }) async {
    try {
      final boundary =
          key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final image = await boundary.toImage(pixelRatio: 3.0);

      // Tạo canvas mới với background
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      final size = Size(
        image.width.toDouble() + padding.horizontal,
        image.height.toDouble() + padding.vertical,
      );

      // Vẽ background
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = backgroundColor,
      );

      // Vẽ image lên canvas
      canvas.drawImage(
        image,
        Offset(padding.left, padding.top),
        Paint(),
      );

      final picture = recorder.endRecording();
      final finalImage = await picture.toImage(
        size.width.toInt(),
        size.height.toInt(),
      );

      final byteData =
          await finalImage.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error capturing mindmap: $e');
      return null;
    }
  }
}
