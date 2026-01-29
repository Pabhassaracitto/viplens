import 'package:flutter/material.dart';

import '../models/mindmap_model.dart';
import '../models/node_model.dart';
import '../utils/colors.dart';

class FlashcardWidget extends StatefulWidget {
  final NodeModel node;
  final MindMapModel? mindmap;
  final bool showAnswer;
  final VoidCallback? onTap;
  final String? hint;

  const FlashcardWidget({
    super.key,
    required this.node,
    this.mindmap,
    this.showAnswer = false,
    this.onTap,
    this.hint,
  });

  @override
  State<FlashcardWidget> createState() => _FlashcardWidgetState();
}

class _FlashcardWidgetState extends State<FlashcardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(FlashcardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showAnswer != oldWidget.showAnswer) {
      if (widget.showAnswer) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final angle = _animation.value * 3.14159;
          final isFront = angle < 3.14159 / 2;

          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            child: isFront
                ? _buildFrontCard()
                : Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(3.14159),
                    child: _buildBackCard(),
                  ),
          );
        },
      ),
    );
  }

  Widget _buildFrontCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Hint (parent node)
          if (widget.hint != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                widget.hint!,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.primary.withOpacity(0.8),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Pali text
          if (widget.node.paliText != null &&
              widget.node.paliText!.isNotEmpty) ...[
            Text(
              widget.node.paliText!,
              style: TextStyle(
                fontSize: 18,
                fontStyle: FontStyle.italic,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
          ],

          // Question (main content)
          Text(
            widget.node.content,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 40),

          // Tap hint
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.touch_app, size: 18, color: Colors.grey[400]),
              const SizedBox(width: 8),
              Text(
                'Chạm để xem đáp án',
                style: TextStyle(fontSize: 14, color: Colors.grey[400]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBackCard() {
    // Lấy các node con làm đáp án
    final children = widget.mindmap?.getChildren(widget.node.id) ?? [];
    final hasChildren = children.isNotEmpty;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Answer label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  size: 16,
                  color: AppColors.success,
                ),
                const SizedBox(width: 6),
                Text(
                  'Đáp án',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Answer content
          if (hasChildren)
            ...children.map(
              (child) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    if (child.paliText != null &&
                        child.paliText!.isNotEmpty) ...[
                      Text(
                        child.paliText!,
                        style: TextStyle(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                    ],
                    Text(
                      child.content,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            // Nếu không có node con, hiện note hoặc thông báo
            Text(
              widget.node.note ?? 'Chưa có đáp án',
              style: TextStyle(
                fontSize: 18,
                color: widget.node.note != null
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }
}

/// Widget đánh giá sau khi xem đáp án
class ReviewButtonsWidget extends StatelessWidget {
  final VoidCallback onForgot;
  final VoidCallback onHard;
  final VoidCallback onGood;
  final VoidCallback onEasy;

  const ReviewButtonsWidget({
    super.key,
    required this.onForgot,
    required this.onHard,
    required this.onGood,
    required this.onEasy,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: _buildButton(
              label: 'Quên',
              emoji: '😞',
              color: AppColors.error,
              onTap: onForgot,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildButton(
              label: 'Khó',
              emoji: '😐',
              color: AppColors.warning,
              onTap: onHard,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildButton(
              label: 'Tốt',
              emoji: '🙂',
              color: AppColors.info,
              onTap: onGood,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildButton(
              label: 'Dễ',
              emoji: '😊',
              color: AppColors.success,
              onTap: onEasy,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton({
    required String label,
    required String emoji,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
