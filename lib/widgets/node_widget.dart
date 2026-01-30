import 'package:flutter/material.dart';
import '../models/node_model.dart';
import '../utils/colors.dart';

class NodeWidget extends StatelessWidget {
  final NodeModel node;
  final bool isSelected;
  final bool isRoot;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final VoidCallback? onLongPress;
  final bool showPaliText;
  final bool isZenMode;

  const NodeWidget({
    super.key,
    required this.node,
    this.isSelected = false,
    this.isRoot = false,
    this.onTap,
    this.onDoubleTap,
    this.onLongPress,
    this.showPaliText = true,
    this.isZenMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final nodeColor = AppColors.getNodeColor(node.colorIndex);
    final hasPali = node.paliText != null && node.paliText!.isNotEmpty;

    // === XÁC ĐỊNH MÀU SẮC ===

    // Màu nền
    Color backgroundColor;
    if (isZenMode) {
      backgroundColor = isSelected ? AppColors.zenAccent : AppColors.zenSurface;
    } else if (isSelected) {
      backgroundColor = nodeColor;
    } else {
      // Nền nhạt khi không được chọn
      backgroundColor = nodeColor.withOpacity(0.15);
    }

    // Màu chữ chính (tiếng Việt)
    Color textColor;
    if (isZenMode) {
      textColor = AppColors.zenText;
    } else if (isSelected) {
      textColor = Colors.white;
    } else {
      // ĐÂY LÀ FIX CHÍNH: Dùng màu tối để dễ đọc trên nền nhạt
      textColor = Colors.grey[850] ?? const Color(0xFF212121);
    }

    // Màu chữ Pali
    Color paliColor;
    if (isZenMode) {
      paliColor = AppColors.zenText.withOpacity(0.7);
    } else if (isSelected) {
      paliColor = Colors.white.withOpacity(0.85);
    } else {
      paliColor = nodeColor.withOpacity(0.8);
    }

    // Màu viền
    Color borderColor = isSelected ? nodeColor : nodeColor.withOpacity(0.4);

    return GestureDetector(
      onTap: onTap,
      onDoubleTap: onDoubleTap,
      onLongPress: onLongPress,
      child: Container(
        constraints: BoxConstraints(
          minWidth: isRoot ? 100 : 60,
          maxWidth: isZenMode ? 250 : 180,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: isRoot ? 20 : 14,
          vertical: isRoot ? 14 : 10,
        ),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(isRoot ? 16 : 12),
          border: Border.all(color: borderColor, width: isSelected ? 2.5 : 1.5),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: nodeColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Pali text (nếu có)
            if (hasPali && showPaliText) ...[
              Text(
                node.paliText!,
                style: TextStyle(
                  fontSize: isRoot ? 13 : 11,
                  fontStyle: FontStyle.italic,
                  color: paliColor,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
            ],

            // Main content (tiếng Việt)
            Text(
              node.content,
              style: TextStyle(
                fontSize: isRoot ? 16 : 14,
                fontWeight: isRoot ? FontWeight.w600 : FontWeight.w500,
                color: textColor,
                // Thêm shadow nhẹ để chữ nổi bật hơn
                shadows: isSelected
                    ? null
                    : [
                        Shadow(
                          color: Colors.white.withOpacity(0.5),
                          blurRadius: 1,
                        ),
                      ],
              ),
              textAlign: TextAlign.center,
              maxLines: isZenMode ? 4 : 3,
              overflow: TextOverflow.ellipsis,
            ),

            // Flashcard indicator
            if (node.isFlashcard) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withOpacity(0.25)
                      : AppColors.accent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.style_outlined,
                      size: 10,
                      color: isSelected ? Colors.white : AppColors.accent,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      'Thẻ',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                        color: isSelected ? Colors.white : AppColors.accent,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Widget hiển thị node trong danh sách (list view)
class NodeListTile extends StatelessWidget {
  final NodeModel node;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onToggleFlashcard;

  const NodeListTile({
    super.key,
    required this.node,
    this.isSelected = false,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onToggleFlashcard,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppColors.getNodeColor(node.colorIndex);
    final hasPali = node.paliText != null && node.paliText!.isNotEmpty;

    return Container(
      margin: EdgeInsets.only(left: node.level * 16.0),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 2),
        color: isSelected ? color.withOpacity(0.1) : null,
        child: ListTile(
          dense: true,
          leading: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          title: Text(
            node.content,
            style: TextStyle(
              fontWeight: node.level == 0 ? FontWeight.w600 : FontWeight.normal,
              color: Colors.grey[850],
            ),
          ),
          subtitle: hasPali
              ? Text(
                  node.paliText!,
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    fontSize: 12,
                    color: color.withOpacity(0.8),
                  ),
                )
              : null,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (node.isFlashcard)
                const Icon(Icons.style, size: 16, color: AppColors.accent),
              if (onEdit != null)
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  onPressed: onEdit,
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          onTap: onTap,
          selected: isSelected,
        ),
      ),
    );
  }
}
