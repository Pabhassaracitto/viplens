import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../models/mindmap_model.dart';
import '../utils/colors.dart';
import '../utils/helpers.dart';

class MindMapCard extends StatelessWidget {
  final MindMapModel mindmap;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onReview;

  const MindMapCard({
    super.key,
    required this.mindmap,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    this.onReview,
  });

  @override
  Widget build(BuildContext context) {
    final dueCount = mindmap.dueFlashcardCount;
    final totalFlashcards = mindmap.flashcardCount;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Slidable(
        key: ValueKey(mindmap.id),
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          children: [
            SlidableAction(
              onPressed: (_) => onEdit(),
              backgroundColor: AppColors.info,
              foregroundColor: Colors.white,
              icon: Icons.edit,
              label: 'Sửa',
            ),
            SlidableAction(
              onPressed: (_) => onDelete(),
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              icon: Icons.delete,
              label: 'Xóa',
            ),
          ],
        ),
        child: Card(
          margin: EdgeInsets.zero,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title row
                  Row(
                    children: [
                      // Icon
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.account_tree_outlined,
                          color: AppColors.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Title and date
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              mindmap.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              Helpers.formatDate(mindmap.updatedAt),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Arrow
                      Icon(Icons.chevron_right, color: Colors.grey[400]),
                    ],
                  ),

                  // Stats row
                  if (totalFlashcards > 0) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        // Node count
                        _buildStatChip(
                          icon: Icons.bubble_chart_outlined,
                          label: '${mindmap.nodes.length} nodes',
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 8),

                        // Flashcard count
                        _buildStatChip(
                          icon: Icons.style_outlined,
                          label: '$totalFlashcards thẻ',
                          color: AppColors.info,
                        ),

                        // Due count
                        if (dueCount > 0) ...[
                          const SizedBox(width: 8),
                          _buildStatChip(
                            icon: Icons.schedule,
                            label: '$dueCount cần ôn',
                            color: AppColors.warning,
                            filled: true,
                          ),
                        ],

                        const Spacer(),

                        // Review button
                        if (dueCount > 0 && onReview != null)
                          TextButton.icon(
                            onPressed: onReview,
                            icon: const Icon(Icons.play_arrow, size: 18),
                            label: const Text('Ôn tập'),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                      ],
                    ),
                  ],

                  // Tags
                  if (mindmap.tags.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: mindmap.tags
                          .map(
                            (tag) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '#$tag',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.primary.withOpacity(0.8),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required Color color,
    bool filled = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: filled ? color.withOpacity(0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: filled ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
