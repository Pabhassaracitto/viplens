import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/review_provider.dart';
import '../utils/colors.dart';
import '../widgets/flashcard_widget.dart';

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ReviewProvider>().loadDueFlashcards();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ReviewProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return Scaffold(
            appBar: AppBar(title: const Text('Ôn tập')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (!provider.hasCards) {
          return Scaffold(
            appBar: AppBar(title: const Text('Ôn tập')),
            body: _buildEmptyState(),
          );
        }

        if (provider.isComplete) {
          return Scaffold(
            appBar: AppBar(title: const Text('Hoàn thành!')),
            body: _buildCompleteState(provider),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(
              '${provider.currentIndex + 1} / ${provider.totalCount}',
            ),
            actions: [
              TextButton(
                onPressed: provider.skipCard,
                child: const Text('Bỏ qua'),
              ),
            ],
          ),
          body: Column(
            children: [
              // Progress bar
              LinearProgressIndicator(
                value: provider.progress,
                backgroundColor: Colors.grey[200],
                valueColor: const AlwaysStoppedAnimation(AppColors.primary),
              ),

              // Card
              Expanded(
                child: FlashcardWidget(
                  node: provider.currentNode!,
                  mindmap: provider.currentMindMap,
                  showAnswer: provider.isShowingAnswer,
                  hint: provider.getHint(),
                  onTap: () {
                    if (!provider.isShowingAnswer) {
                      provider.showAnswer();
                    }
                  },
                ),
              ),

              // Review buttons (only show when answer is visible)
              if (provider.isShowingAnswer) ...[
                ReviewButtonsWidget(
                  onForgot: provider.markForgot,
                  onHard: provider.markHard,
                  onGood: provider.markGood,
                  onEasy: provider.markEasy,
                ),
                const SizedBox(height: 16),
              ] else ...[
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: provider.showAnswer,
                      icon: const Icon(Icons.visibility),
                      label: const Text('Hiện đáp án'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.celebration, size: 80, color: AppColors.success),
            const SizedBox(height: 24),
            Text(
              'Tuyệt vời!',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Không có thẻ nào cần ôn tập.\nHãy quay lại sau nhé!',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Quay lại'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompleteState(ReviewProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Success icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                size: 60,
                color: AppColors.success,
              ),
            ),

            const SizedBox(height: 32),

            Text(
              'Hoàn thành!',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 16),

            Text(
              'Bạn đã ôn tập ${provider.reviewedCount} thẻ',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
            ),

            const SizedBox(height: 48),

            // Stats
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _buildStatRow(
                    icon: Icons.style,
                    label: 'Tổng thẻ đã ôn',
                    value: '${provider.reviewedCount}',
                  ),
                  const Divider(height: 24),
                  _buildStatRow(
                    icon: Icons.timer,
                    label: 'Thời gian',
                    value: '~ ${provider.reviewedCount * 10} giây',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    provider.loadDueFlashcards();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Ôn lại'),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.home),
                  label: const Text('Về trang chủ'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 12),
        Text(label),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
