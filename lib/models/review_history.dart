import 'package:hive/hive.dart';

part 'review_history.g.dart';

@HiveType(typeId: 3)
class ReviewHistory extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String nodeId;

  @HiveField(2)
  final String mindmapId;

  @HiveField(3)
  final DateTime reviewedAt;

  @HiveField(4)
  final int quality; // 0-5

  @HiveField(5)
  final int previousInterval;

  @HiveField(6)
  final int newInterval;

  @HiveField(7)
  final double previousEaseFactor;

  @HiveField(8)
  final double newEaseFactor;

  ReviewHistory({
    required this.id,
    required this.nodeId,
    required this.mindmapId,
    required this.reviewedAt,
    required this.quality,
    required this.previousInterval,
    required this.newInterval,
    required this.previousEaseFactor,
    required this.newEaseFactor,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nodeId': nodeId,
      'mindmapId': mindmapId,
      'reviewedAt': reviewedAt.toIso8601String(),
      'quality': quality,
      'previousInterval': previousInterval,
      'newInterval': newInterval,
      'previousEaseFactor': previousEaseFactor,
      'newEaseFactor': newEaseFactor,
    };
  }

  factory ReviewHistory.fromJson(Map<String, dynamic> json) {
    return ReviewHistory(
      id: json['id'] as String,
      nodeId: json['nodeId'] as String,
      mindmapId: json['mindmapId'] as String,
      reviewedAt: DateTime.parse(json['reviewedAt'] as String),
      quality: json['quality'] as int,
      previousInterval: json['previousInterval'] as int,
      newInterval: json['newInterval'] as int,
      previousEaseFactor: (json['previousEaseFactor'] as num).toDouble(),
      newEaseFactor: (json['newEaseFactor'] as num).toDouble(),
    );
  }
}

/// Thống kê ôn tập theo ngày
class DailyReviewStats {
  final DateTime date;
  final int totalReviewed;
  final int easyCount;
  final int goodCount;
  final int hardCount;
  final int forgotCount;

  DailyReviewStats({
    required this.date,
    required this.totalReviewed,
    required this.easyCount,
    required this.goodCount,
    required this.hardCount,
    required this.forgotCount,
  });

  double get successRate {
    if (totalReviewed == 0) return 0;
    return (easyCount + goodCount) / totalReviewed * 100;
  }
}

/// Thống kê tổng quan
class OverallStats {
  final int totalMindmaps;
  final int totalNodes;
  final int totalFlashcards;
  final int masteredCards;
  final int learningCards;
  final int newCards;
  final int totalReviews;
  final double averageEaseFactor;
  final int currentStreak;
  final int longestStreak;

  OverallStats({
    required this.totalMindmaps,
    required this.totalNodes,
    required this.totalFlashcards,
    required this.masteredCards,
    required this.learningCards,
    required this.newCards,
    required this.totalReviews,
    required this.averageEaseFactor,
    required this.currentStreak,
    required this.longestStreak,
  });
}
