// Giai đoạn 2
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/review_history.dart';
import '../utils/colors.dart';

class WeeklyStatsChart extends StatelessWidget {
  final List<DailyReviewStats> stats;

  const WeeklyStatsChart({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    if (stats.isEmpty) {
      return const Center(child: Text('Chưa có dữ liệu'));
    }

    final maxY = stats
        .map((s) => s.totalReviewed)
        .reduce((a, b) => a > b ? a : b);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: (maxY + 5).toDouble(),
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: Colors.grey[800],
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final stat = stats[group.x.toInt()];
              return BarTooltipItem(
                '${stat.totalReviewed} thẻ\n${stat.successRate.toStringAsFixed(0)}% đúng',
                const TextStyle(color: Colors.white, fontSize: 12),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= stats.length) {
                  return const SizedBox.shrink();
                }
                final date = stats[index].date;
                final weekdays = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    weekdays[date.weekday - 1],
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                );
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value == 0) return const SizedBox.shrink();
                return Text(
                  value.toInt().toString(),
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                );
              },
              reservedSize: 30,
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: FlGridData(
          show: true,
          horizontalInterval: 5,
          getDrawingHorizontalLine: (value) =>
              FlLine(color: Colors.grey.withOpacity(0.2), strokeWidth: 1),
          drawVerticalLine: false,
        ),
        borderData: FlBorderData(show: false),
        barGroups: stats.asMap().entries.map((entry) {
          final index = entry.key;
          final stat = entry.value;

          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: stat.totalReviewed.toDouble(),
                width: 20,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.7),
                    AppColors.primary,
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class MasteryPieChart extends StatelessWidget {
  final int mastered;
  final int learning;
  final int newCards;

  const MasteryPieChart({
    super.key,
    required this.mastered,
    required this.learning,
    required this.newCards,
  });

  @override
  Widget build(BuildContext context) {
    final total = mastered + learning + newCards;
    if (total == 0) {
      return const Center(child: Text('Chưa có thẻ'));
    }

    return Row(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 30,
              sections: [
                PieChartSectionData(
                  value: mastered.toDouble(),
                  title: mastered > 0 ? '$mastered' : '',
                  color: AppColors.success,
                  radius: 40,
                  titleStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                PieChartSectionData(
                  value: learning.toDouble(),
                  title: learning > 0 ? '$learning' : '',
                  color: AppColors.warning,
                  radius: 40,
                  titleStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                PieChartSectionData(
                  value: newCards.toDouble(),
                  title: newCards > 0 ? '$newCards' : '',
                  color: AppColors.info,
                  radius: 40,
                  titleStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLegend(AppColors.success, 'Thành thạo', mastered),
            const SizedBox(height: 8),
            _buildLegend(AppColors.warning, 'Đang học', learning),
            const SizedBox(height: 8),
            _buildLegend(AppColors.info, 'Mới', newCards),
          ],
        ),
      ],
    );
  }

  Widget _buildLegend(Color color, String label, int count) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text('$label: $count', style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class StreakWidget extends StatelessWidget {
  final int currentStreak;
  final int longestStreak;

  const StreakWidget({
    super.key,
    required this.currentStreak,
    required this.longestStreak,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildStreakCard(
            icon: Icons.local_fire_department,
            label: 'Chuỗi hiện tại',
            value: currentStreak,
            color: currentStreak > 0 ? AppColors.warning : Colors.grey,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStreakCard(
            icon: Icons.emoji_events,
            label: 'Kỷ lục',
            value: longestStreak,
            color: AppColors.accent,
          ),
        ),
      ],
    );
  }

  Widget _buildStreakCard({
    required IconData icon,
    required String label,
    required int value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            '$value ngày',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }
}
