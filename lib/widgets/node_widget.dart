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
    final color = AppColors.getNodeColor(node.colorIndex);
    final hasPali = node.paliText != null && node.paliText!.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      onDoubleTap: onDoubleTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        constraints: BoxConstraints(
          minWidth: isRoot ? 100 : 60,
          maxWidth: isZenMode ? 250 : 180,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: isRoot ? 20 : 14,
          vertical: isRoot ? 14 : 10,
        ),
        decoration: BoxDecoration(
          color: isZenMode
              ? AppColors.zenSurface
              : (isSelected ? color : color.withOpacity(0.12)),
          borderRadius: BorderRadius.circular(isRoot ? 16 : 12),
          border: Border.all(
            color: isSelected ? color : color.withOpacity(0.3),
            width: isSelected ? 2.5 : 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
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
                  color: isSelected
                      ? Colors.white.withOpacity(0.8)
                      : (isZenMode
                            ? AppColors.zenText.withOpacity(0.7)
                            : color.withOpacity(0.7)),
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
            ],

            // Main content
            Text(
              node.content,
              style: TextStyle(
                fontSize: isRoot ? 16 : 14,
                fontWeight: isRoot ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : (isZenMode ? AppColors.zenText : AppColors.textPrimary),
              ),
              textAlign: TextAlign.center,
              maxLines: isZenMode ? 4 : 3,
              overflow: TextOverflow.ellipsis,
            ),

            // Flashcard indicator
            if (node.isFlashcard) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withOpacity(0.2)
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
                    const SizedBox(width: 2),
                    Text(
                      'Thẻ',
                      style: TextStyle(
                        fontSize: 9,
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
            ),
          ),
          subtitle: hasPali
              ? Text(
                  node.paliText!,
                  style: const TextStyle(
                    fontStyle: FontStyle.italic,
                    fontSize: 12,
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
