import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Các hàm helper tiện ích
class Helpers {
  /// Format ngày tháng
  static String formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Hôm nay';
    } else if (dateOnly == yesterday) {
      return 'Hôm qua';
    } else if (now.difference(date).inDays < 7) {
      return '${now.difference(date).inDays} ngày trước';
    } else {
      return DateFormat('dd/MM/yyyy').format(date);
    }
  }

  /// Format thời gian đầy đủ
  static String formatDateTime(DateTime date) {
    return DateFormat('HH:mm - dd/MM/yyyy').format(date);
  }

  /// Format số lượng
  static String formatCount(int count, String singular, String plural) {
    if (count == 0) return 'Không có $singular';
    if (count == 1) return '1 $singular';
    return '$count $plural';
  }

  /// Rút gọn text
  static String truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  /// Hiển thị snackbar
  static void showSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
    Duration duration = const Duration(seconds: 2),
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red[700] : null,
        duration: duration,
        action: action,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  /// Hiển thị dialog xác nhận
  static Future<bool> showConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Xác nhận',
    String cancelText = 'Hủy',
    bool isDestructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelText),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: isDestructive
                ? TextButton.styleFrom(foregroundColor: Colors.red)
                : null,
            child: Text(confirmText),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// Hiển thị dialog nhập text
  static Future<String?> showInputDialog(
    BuildContext context, {
    required String title,
    String? initialValue,
    String? hintText,
    String confirmText = 'Lưu',
    String cancelText = 'Hủy',
    int maxLines = 1,
    int? maxLength,
  }) async {
    final controller = TextEditingController(text: initialValue);

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: maxLines,
          maxLength: maxLength,
          decoration: InputDecoration(
            hintText: hintText,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(cancelText),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(confirmText),
          ),
        ],
      ),
    );

    //controller.dispose();
    return result;
  }

  /// Hiển thị bottom sheet chọn option
  static Future<T?> showOptionsBottomSheet<T>(
    BuildContext context, {
    required String title,
    required List<OptionItem<T>> options,
  }) async {
    return showModalBottomSheet<T>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const Divider(height: 1),
            ...options.map(
              (option) => ListTile(
                leading: option.icon != null ? Icon(option.icon) : null,
                title: Text(option.title),
                subtitle: option.subtitle != null
                    ? Text(option.subtitle!)
                    : null,
                onTap: () => Navigator.pop(context, option.value),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

/// Model cho option trong bottom sheet
class OptionItem<T> {
  final T value;
  final String title;
  final String? subtitle;
  final IconData? icon;

  OptionItem({
    required this.value,
    required this.title,
    this.subtitle,
    this.icon,
  });
}

/// Extension cho BuildContext
extension ContextExtension on BuildContext {
  /// Lấy theme
  ThemeData get theme => Theme.of(this);

  /// Lấy text theme
  TextTheme get textTheme => Theme.of(this).textTheme;

  /// Lấy color scheme
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  /// Lấy media query
  MediaQueryData get mediaQuery => MediaQuery.of(this);

  /// Lấy size màn hình
  Size get screenSize => MediaQuery.of(this).size;

  /// Kiểm tra dark mode
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
}
