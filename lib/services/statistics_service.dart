import 'package:hive_flutter/hive_flutter.dart';
import '../models/review_history.dart';
import 'database_service.dart';

class StatisticsService {
  static const String _historyBoxName = 'review_history';
  static const String _streakBoxName = 'streaks';

  static late Box<ReviewHistory> _historyBox;
  static late Box<dynamic> _streakBox;

  /// Khởi tạo
  static Future<void> initialize() async {
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(ReviewHistoryAdapter());
    }
    _historyBox = await Hive.openBox<ReviewHistory>(_historyBoxName);
    _streakBox = await Hive.openBox(_streakBoxName);
  }

  /// Ghi lại lịch sử ôn tập
  static Future<void> recordReview({
    required String nodeId,
    required String mindmapId,
    required int quality,
    required int previousInterval,
    required int newInterval,
    required double previousEaseFactor,
    required double newEaseFactor,
  }) async {
    final history = ReviewHistory(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      nodeId: nodeId,
      mindmapId: mindmapId,
      reviewedAt: DateTime.now(),
      quality: quality,
      previousInterval: previousInterval,
      newInterval: newInterval,
      previousEaseFactor: previousEaseFactor,
      newEaseFactor: newEaseFactor,
    );

    await _historyBox.add(history);
    await _updateStreak();
  }

  /// Cập nhật streak
  static Future<void> _updateStreak() async {
    final today = DateTime.now();
    final todayKey = '${today.year}-${today.month}-${today.day}';
    final yesterdayKey = () {
      final yesterday = today.subtract(const Duration(days: 1));
      return '${yesterday.year}-${yesterday.month}-${yesterday.day}';
    }();

    // Đánh dấu hôm nay đã ôn tập
    await _streakBox.put(todayKey, true);

    // Tính current streak
    int currentStreak = 0;
    var checkDate = today;

    while (true) {
      final key = '${checkDate.year}-${checkDate.month}-${checkDate.day}';
      if (_streakBox.get(key) == true) {
        currentStreak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    await _streakBox.put('currentStreak', currentStreak);

    // Cập nhật longest streak
    final longestStreak =
        _streakBox.get('longestStreak', defaultValue: 0) as int;
    if (currentStreak > longestStreak) {
      await _streakBox.put('longestStreak', currentStreak);
    }
  }

  /// Lấy current streak
  static int getCurrentStreak() {
    return _streakBox.get('currentStreak', defaultValue: 0) as int;
  }

  /// Lấy longest streak
  static int getLongestStreak() {
    return _streakBox.get('longestStreak', defaultValue: 0) as int;
  }

  /// Lấy thống kê theo ngày (7 ngày gần nhất)
  static List<DailyReviewStats> getWeeklyStats() {
    final stats = <DailyReviewStats>[];
    final now = DateTime.now();

    for (int i = 6; i >= 0; i--) {
      final date = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: i));
      final nextDate = date.add(const Duration(days: 1));

      final dayHistory = _historyBox.values.where((h) {
        return h.reviewedAt.isAfter(date) && h.reviewedAt.isBefore(nextDate);
      }).toList();

      int easy = 0, good = 0, hard = 0, forgot = 0;
      for (final h in dayHistory) {
        if (h.quality >= 4) {
          easy++;
        } else if (h.quality == 3) {
          good++;
        } else if (h.quality >= 1) {
          hard++;
        } else {
          forgot++;
        }
      }

      stats.add(
        DailyReviewStats(
          date: date,
          totalReviewed: dayHistory.length,
          easyCount: easy,
          goodCount: good,
          hardCount: hard,
          forgotCount: forgot,
        ),
      );
    }

    return stats;
  }

  /// Lấy thống kê tổng quan
  static OverallStats getOverallStats() {
    final mindmaps = DatabaseService.getAllMindMaps();

    int totalNodes = 0;
    int totalFlashcards = 0;
    int masteredCards = 0;
    int learningCards = 0;
    int newCards = 0;
    double totalEaseFactor = 0;
    int easeFactorCount = 0;

    for (final map in mindmaps) {
      totalNodes += map.nodes.length;

      for (final node in map.nodes) {
        if (!node.isFlashcard) continue;

        totalFlashcards++;
        totalEaseFactor += node.easeFactor;
        easeFactorCount++;

        if (node.intervalDays >= 21) {
          masteredCards++;
        } else if (node.repetitionCount > 0) {
          learningCards++;
        } else {
          newCards++;
        }
      }
    }

    return OverallStats(
      totalMindmaps: mindmaps.length,
      totalNodes: totalNodes,
      totalFlashcards: totalFlashcards,
      masteredCards: masteredCards,
      learningCards: learningCards,
      newCards: newCards,
      totalReviews: _historyBox.length,
      averageEaseFactor:
          easeFactorCount > 0 ? totalEaseFactor / easeFactorCount : 2.5,
      currentStreak: getCurrentStreak(),
      longestStreak: getLongestStreak(),
    );
  }

  /// Lấy lịch sử ôn tập của một node
  static List<ReviewHistory> getNodeHistory(String nodeId) {
    return _historyBox.values.where((h) => h.nodeId == nodeId).toList()
      ..sort((a, b) => b.reviewedAt.compareTo(a.reviewedAt));
  }

  /// Lấy số lượng ôn tập hôm nay
  static int getTodayReviewCount() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    return _historyBox.values.where((h) {
      return h.reviewedAt.isAfter(today) && h.reviewedAt.isBefore(tomorrow);
    }).length;
  }
}
