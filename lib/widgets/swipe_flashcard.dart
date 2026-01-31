// Giai đoạn 2
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import '../models/node_model.dart';
import '../models/mindmap_model.dart';
import '../models/review_data.dart';
import '../utils/colors.dart';

class SwipeFlashcardWidget extends StatefulWidget {
  final List<MapEntry<MindMapModel, NodeModel>> cards;
  final Function(int index, ReviewQuality quality) onSwipe;
  final VoidCallback? onComplete;

  const SwipeFlashcardWidget({
    super.key,
    required this.cards,
    required this.onSwipe,
    this.onComplete,
  });

  @override
  State<SwipeFlashcardWidget> createState() => _SwipeFlashcardWidgetState();
}

class _SwipeFlashcardWidgetState extends State<SwipeFlashcardWidget> {
  final CardSwiperController _controller = CardSwiperController();
  int _currentIndex = 0;
  bool _showingAnswer = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleAnswer() {
    setState(() {
      _showingAnswer = !_showingAnswer;
    });
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.cards.isEmpty) {
      return const Center(child: Text('Không có thẻ nào'));
    }

    return Column(
      children: [
        // Progress
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(
                '${_currentIndex + 1} / ${widget.cards.length}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: LinearProgressIndicator(
                  value: (_currentIndex + 1) / widget.cards.length,
                  backgroundColor: Colors.grey[200],
                ),
              ),
            ],
          ),
        ),

        // Cards
        Expanded(
          child: CardSwiper(
            controller: _controller,
            cardsCount: widget.cards.length,
            numberOfCardsDisplayed: 2,
            backCardOffset: const Offset(0, 40),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            onSwipe: (previousIndex, currentIndex, direction) {
              ReviewQuality quality;
              switch (direction) {
                case CardSwiperDirection.left:
                  quality = ReviewQuality.forgot;
                  break;
                case CardSwiperDirection.right:
                  quality = ReviewQuality.good;
                  break;
                case CardSwiperDirection.top:
                  quality = ReviewQuality.easy;
                  break;
                case CardSwiperDirection.bottom:
                  quality = ReviewQuality.difficult;
                  break;
                default:
                  quality = ReviewQuality.good;
              }

              widget.onSwipe(previousIndex, quality);

              setState(() {
                _currentIndex = currentIndex ?? _currentIndex + 1;
                _showingAnswer = false;
              });

              HapticFeedback.mediumImpact();
              return true;
            },
            onEnd: widget.onComplete,
            cardBuilder:
                (context, index, percentThresholdX, percentThresholdY) {
                  final card = widget.cards[index];
                  final node = card.value;
                  final mindmap = card.key;
                  final isCurrentCard = index == _currentIndex;

                  return GestureDetector(
                    onTap: isCurrentCard ? _toggleAnswer : null,
                    child: _buildCard(node, mindmap, isCurrentCard),
                  );
                },
          ),
        ),

        // Swipe hints
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildHint(Icons.arrow_back, 'Quên', AppColors.error),
              _buildHint(Icons.arrow_downward, 'Khó', AppColors.warning),
              _buildHint(Icons.arrow_upward, 'Dễ', AppColors.success),
              _buildHint(Icons.arrow_forward, 'Tốt', AppColors.info),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCard(NodeModel node, MindMapModel mindmap, bool isCurrentCard) {
    final showAnswer = isCurrentCard && _showingAnswer;
    final children = mindmap.getChildren(node.id);
    final parent = node.parentId != null
        ? mindmap.getNodeById(node.parentId!)
        : null;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutBack,
      decoration: BoxDecoration(
        color: showAnswer
            ? AppColors.primary.withOpacity(0.05)
            : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: showAnswer
              ? AppColors.primary.withOpacity(0.3)
              : Colors.grey.withOpacity(0.2),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Hint (parent node)
            if (parent != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  parent.content,
                  style: TextStyle(fontSize: 12, color: AppColors.primary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Flashcard indicator
            if (node.isFlashcard)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.style, size: 14, color: AppColors.accent),
                    const SizedBox(width: 4),
                    Text(
                      'Thẻ ghi nhớ',
                      style: TextStyle(fontSize: 11, color: AppColors.accent),
                    ),
                  ],
                ),
              ),

            const Spacer(),

            // Question
            if (!showAnswer) ...[
              if (node.paliText != null && node.paliText!.isNotEmpty) ...[
                Text(
                  node.paliText!,
                  style: TextStyle(
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
              ],
              Text(
                node.content,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.touch_app, size: 16, color: Colors.grey[400]),
                  const SizedBox(width: 8),
                  Text(
                    'Chạm để xem đáp án',
                    style: TextStyle(fontSize: 13, color: Colors.grey[400]),
                  ),
                ],
              ),
            ] else ...[
              // Answer
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lightbulb, size: 16, color: AppColors.success),
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
              if (children.isNotEmpty)
                ...children
                    .take(5)
                    .map(
                      (child) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Column(
                          children: [
                            if (child.paliText != null &&
                                child.paliText!.isNotEmpty)
                              Text(
                                child.paliText!,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey[600],
                                ),
                                textAlign: TextAlign.center,
                              ),
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
                Text(
                  node.note ?? 'Chưa có đáp án',
                  style: TextStyle(
                    fontSize: 18,
                    color: node.note != null ? null : Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              const Spacer(),
              Text(
                'Vuốt để đánh giá',
                style: TextStyle(fontSize: 13, color: Colors.grey[400]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHint(IconData icon, String label, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 11, color: color)),
      ],
    );
  }
}
