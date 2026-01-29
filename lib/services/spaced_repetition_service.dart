import '../models/node_model.dart';
import '../models/review_data.dart';
import '../models/mindmap_model.dart';

/// Service xử lý thuật toán Spaced Repetition SM-2
class SpacedRepetitionService {
  /// Tính toán lịch ôn tập tiếp theo dựa trên chất lượng trả lời
  ///
  /// Thuật toán SM-2:
  /// - Nếu quality < 3: Reset về đầu
  /// - Nếu quality >= 3: Tăng interval theo công thức
  /// - EaseFactor được điều chỉnh dựa trên quality
  static ReviewResult calculateNextReview({
    required ReviewQuality quality,
    required int currentRepetition,
    required double currentEaseFactor,
    required int currentInterval,
  }) {
    double newEaseFactor = currentEaseFactor;
    int newRepetition = currentRepetition;
    int newInterval = currentInterval;

    if (quality.value < 3) {
      // Quên - reset lại từ đầu
      newRepetition = 0;
      newInterval = 1;
    } else {
      // Nhớ - tiếp tục tăng interval
      if (currentRepetition == 0) {
        newInterval = 1;
      } else if (currentRepetition == 1) {
        newInterval = 6;
      } else {
        newInterval = (currentInterval * currentEaseFactor).round();
      }
      newRepetition = currentRepetition + 1;
    }

    // Cập nhật EaseFactor
    // EF' = EF + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02))
    newEaseFactor =
        currentEaseFactor +
        (0.1 - (5 - quality.value) * (0.08 + (5 - quality.value) * 0.02));

    // EaseFactor không được nhỏ hơn 1.3
    if (newEaseFactor < 1.3) {
      newEaseFactor = 1.3;
    }

    // Tính ngày ôn tập tiếp theo
    final nextReviewDate = DateTime.now().add(Duration(days: newInterval));

    return ReviewResult(
      nextReviewDate: nextReviewDate,
      repetitionCount: newRepetition,
      easeFactor: newEaseFactor,
      intervalDays: newInterval,
    );
  }

  /// Cập nhật node sau khi ôn tập
  static NodeModel updateNodeAfterReview(
    NodeModel node,
    ReviewQuality quality,
  ) {
    final result = calculateNextReview(
      quality: quality,
      currentRepetition: node.repetitionCount,
      currentEaseFactor: node.easeFactor,
      currentInterval: node.intervalDays,
    );

    return node.copyWith(
      nextReviewDate: result.nextReviewDate,
      repetitionCount: result.repetitionCount,
      easeFactor: result.easeFactor,
      intervalDays: result.intervalDays,
    );
  }

  /// Cập nhật mindmap sau khi ôn tập một node
  static MindMapModel updateMindMapAfterReview(
    MindMapModel mindmap,
    String nodeId,
    ReviewQuality quality,
  ) {
    final nodeIndex = mindmap.nodes.indexWhere((n) => n.id == nodeId);
    if (nodeIndex < 0) return mindmap;

    final updatedNode = updateNodeAfterReview(
      mindmap.nodes[nodeIndex],
      quality,
    );
    final updatedNodes = List<NodeModel>.from(mindmap.nodes);
    updatedNodes[nodeIndex] = updatedNode;

    return mindmap.copyWith(nodes: updatedNodes, updatedAt: DateTime.now());
  }

  /// Tính thống kê ôn tập cho một mindmap
  static ReviewStats calculateStats(MindMapModel mindmap) {
    final flashcards = mindmap.nodes.where((n) => n.isFlashcard).toList();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    int dueToday = 0;
    int masteredCards = 0;
    double totalEaseFactor = 0;

    for (final card in flashcards) {
      if (card.nextReviewDate != null) {
        final reviewDate = DateTime(
          card.nextReviewDate!.year,
          card.nextReviewDate!.month,
          card.nextReviewDate!.day,
        );
        if (reviewDate.compareTo(today) <= 0) {
          dueToday++;
        }
      }

      // Card được coi là "mastered" nếu interval >= 21 ngày
      if (card.intervalDays >= 21) {
        masteredCards++;
      }

      totalEaseFactor += card.easeFactor;
    }

    return ReviewStats(
      totalCards: flashcards.length,
      dueToday: dueToday,
      reviewedToday: 0, // Cần tracking riêng nếu muốn
      masteredCards: masteredCards,
      averageEaseFactor: flashcards.isEmpty
          ? 2.5
          : totalEaseFactor / flashcards.length,
    );
  }

  /// Tính tổng thống kê cho tất cả mindmaps
  static ReviewStats calculateTotalStats(List<MindMapModel> mindmaps) {
    int totalCards = 0;
    int dueToday = 0;
    int masteredCards = 0;
    double totalEaseFactor = 0;
    int cardCount = 0;

    for (final mindmap in mindmaps) {
      final stats = calculateStats(mindmap);
      totalCards += stats.totalCards;
      dueToday += stats.dueToday;
      masteredCards += stats.masteredCards;

      final flashcards = mindmap.nodes.where((n) => n.isFlashcard);
      for (final card in flashcards) {
        totalEaseFactor += card.easeFactor;
        cardCount++;
      }
    }

    return ReviewStats(
      totalCards: totalCards,
      dueToday: dueToday,
      reviewedToday: 0,
      masteredCards: masteredCards,
      averageEaseFactor: cardCount == 0 ? 2.5 : totalEaseFactor / cardCount,
    );
  }

  /// Lấy mô tả interval bằng tiếng Việt
  static String getIntervalDescription(int days) {
    if (days == 0) return 'Hôm nay';
    if (days == 1) return 'Ngày mai';
    if (days < 7) return '$days ngày';
    if (days < 30) return '${(days / 7).round()} tuần';
    if (days < 365) return '${(days / 30).round()} tháng';
    return '${(days / 365).round()} năm';
  }

  /// Lấy màu dựa trên mức độ thành thạo
  static int getMasteryColorIndex(NodeModel node) {
    if (!node.isFlashcard) return node.colorIndex;

    // Dựa trên interval để xác định mức độ thành thạo
    if (node.intervalDays >= 30) return 5; // Xanh lá - Thành thạo
    if (node.intervalDays >= 14) return 4; // Xanh dương - Khá
    if (node.intervalDays >= 7) return 3; // Vàng - Trung bình
    if (node.intervalDays >= 3) return 2; // Cam - Đang học
    return 1; // Đỏ - Mới
  }
}
