import 'package:flutter/material.dart';

/// Bảng màu của ứng dụng
class AppColors {
  // Primary colors
  static const Color primary = Color(0xFF5C6BC0); // Indigo 400
  static const Color primaryLight = Color(0xFF8E99A4);
  static const Color primaryDark = Color(0xFF3949AB);

  // Accent colors
  static const Color accent = Color(0xFFFFB74D); // Amber 300
  static const Color accentLight = Color(0xFFFFE97D);
  static const Color accentDark = Color(0xFFC88719);

  // Semantic colors
  static const Color success = Color(0xFF66BB6A); // Green 400
  static const Color warning = Color(0xFFFFA726); // Orange 400
  static const Color error = Color(0xFFEF5350); // Red 400
  static const Color info = Color(0xFF42A5F5); // Blue 400

  // Neutral colors
  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color divider = Color(0xFFE0E0E0);

  // Dark theme colors
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color textPrimaryDark = Color(0xFFE0E0E0);
  static const Color textSecondaryDark = Color(0xFF9E9E9E);

  // Node colors - Màu cho các cấp độ node
  static const List<Color> nodeColors = [
    Color(0xFF5C6BC0), // Level 0 - Indigo (Root)
    Color(0xFF42A5F5), // Level 1 - Blue
    Color(0xFF26A69A), // Level 2 - Teal
    Color(0xFF66BB6A), // Level 3 - Green
    Color(0xFFFFCA28), // Level 4 - Amber
    Color(0xFFFF7043), // Level 5 - Deep Orange
    Color(0xFFAB47BC), // Level 6 - Purple
    Color(0xFFEC407A), // Level 7 - Pink
  ];

  // Flashcard mastery colors
  static const List<Color> masteryColors = [
    Color(0xFFE0E0E0), // 0 - Not started
    Color(0xFFEF5350), // 1 - New (Red)
    Color(0xFFFF7043), // 2 - Learning (Orange)
    Color(0xFFFFCA28), // 3 - Familiar (Yellow)
    Color(0xFF42A5F5), // 4 - Good (Blue)
    Color(0xFF66BB6A), // 5 - Mastered (Green)
  ];

  // Zen mode colors
  static const Color zenBackground = Color(0xFF1A1A2E);
  static const Color zenSurface = Color(0xFF16213E);
  static const Color zenText = Color(0xFFE8E8E8);
  static const Color zenAccent = Color(0xFF7F5AF0);

  /// Lấy màu node theo level
  static Color getNodeColor(int level) {
    return nodeColors[level % nodeColors.length];
  }

  /// Lấy màu node sáng hơn (cho background)
  static Color getNodeColorLight(int level) {
    return getNodeColor(level).withOpacity(0.15);
  }

  /// Lấy màu mastery
  static Color getMasteryColor(int index) {
    if (index < 0) return masteryColors[0];
    if (index >= masteryColors.length) return masteryColors.last;
    return masteryColors[index];
  }
}

/// Extension để dễ sử dụng
extension ColorExtension on Color {
  /// Làm sáng màu
  Color lighten([double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    return Color.lerp(this, Colors.white, amount)!;
  }

  /// Làm tối màu
  Color darken([double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    return Color.lerp(this, Colors.black, amount)!;
  }
}
