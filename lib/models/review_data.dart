/// Kết quả tính toán ôn tập theo thuật toán SM-2
class ReviewResult {
  final DateTime nextReviewDate;
  final int repetitionCount;
  final double easeFactor;
  final int intervalDays;

  ReviewResult({
    required this.nextReviewDate,
    required this.repetitionCount,
    required this.easeFactor,
    required this.intervalDays,
  });

  @override
  String toString() {
    return 'ReviewResult(nextReview: $nextReviewDate, interval: $intervalDays days)';
  }
}

/// Chất lượng trả lời khi ôn tập
enum ReviewQuality {
  /// Hoàn toàn quên
  forgot(0, 'Quên hoàn toàn', '😞'),

  /// Nhớ sai nhiều
  hardRecall(1, 'Nhớ rất khó', '😓'),

  /// Nhớ với khó khăn
  difficult(2, 'Nhớ khó', '😐'),

  /// Nhớ với chút khó khăn
  good(3, 'Nhớ được', '🙂'),

  /// Nhớ dễ dàng
  easy(4, 'Nhớ dễ', '😊'),

  /// Nhớ hoàn hảo
  perfect(5, 'Nhớ rõ', '😄');

  final int value;
  final String label;
  final String emoji;

  const ReviewQuality(this.value, this.label, this.emoji);
}

/// Thống kê ôn tập
class ReviewStats {
  final int totalCards;
  final int dueToday;
  final int reviewedToday;
  final int masteredCards;
  final double averageEaseFactor;

  ReviewStats({
    required this.totalCards,
    required this.dueToday,
    required this.reviewedToday,
    required this.masteredCards,
    required this.averageEaseFactor,
  });

  double get progressPercent {
    if (dueToday == 0) return 100;
    return (reviewedToday / (reviewedToday + dueToday)) * 100;
  }
}
