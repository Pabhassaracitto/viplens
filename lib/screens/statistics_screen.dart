// Giai đoạn 2
import 'package:flutter/material.dart';
import '../models/review_history.dart';
import '../services/statistics_service.dart';
import '../widgets/stats_chart.dart';
import '../utils/colors.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  late OverallStats _overallStats;
  late List<DailyReviewStats> _weeklyStats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);

    _overallStats = StatisticsService.getOverallStats();
    _weeklyStats = StatisticsService.getWeeklyStats();

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thống kê')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStats,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Streak
                    StreakWidget(
                      currentStreak: _overallStats.currentStreak,
                      longestStreak: _overallStats.longestStreak,
                    ),

                    const SizedBox(height: 24),

                    // Overview cards
                    Text(
                      'Tổng quan',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    _buildOverviewCards(),

                    const SizedBox(height: 24),

                    // Weekly chart
                    Text(
                      'Ôn tập 7 ngày qua',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 200,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: WeeklyStatsChart(stats: _weeklyStats),
                    ),

                    const SizedBox(height: 24),

                    // Mastery distribution
                    Text(
                      'Phân bố thẻ',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 150,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: MasteryPieChart(
                        mastered: _overallStats.masteredCards,
                        learning: _overallStats.learningCards,
                        newCards: _overallStats.newCards,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Today's stats
                    _buildTodayStats(),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildOverviewCards() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          icon: Icons.account_tree,
          label: 'Sơ đồ',
          value: _overallStats.totalMindmaps.toString(),
          color: AppColors.primary,
        ),
        _buildStatCard(
          icon: Icons.bubble_chart,
          label: 'Nodes',
          value: _overallStats.totalNodes.toString(),
          color: AppColors.info,
        ),
        _buildStatCard(
          icon: Icons.style,
          label: 'Thẻ ghi nhớ',
          value: _overallStats.totalFlashcards.toString(),
          color: AppColors.accent,
        ),
        _buildStatCard(
          icon: Icons.check_circle,
          label: 'Lần ôn tập',
          value: _overallStats.totalReviews.toString(),
          color: AppColors.success,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildTodayStats() {
    final todayCount = StatisticsService.getTodayReviewCount();
    final todayStats = _weeklyStats.isNotEmpty ? _weeklyStats.last : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.today, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Hôm nay',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                Text(
                  '$todayCount thẻ đã ôn',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (todayStats != null && todayStats.totalReviewed > 0)
                  Text(
                    'Tỷ lệ đúng: ${todayStats.successRate.toStringAsFixed(0)}%',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 13,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
