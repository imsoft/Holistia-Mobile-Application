import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../repositories/check_in_repository.dart';
import '../theme/app_theme.dart';

/// Gráfico de barras de los últimos 7 días de check-ins.
class WeeklyChart extends StatelessWidget {
  const WeeklyChart({super.key, required this.stats});

  final List<DayStat> stats;

  static const _dayLabels = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppThemeExtension>();
    final primaryColor = theme?.primary ?? Theme.of(context).colorScheme.primary;
    final mutedColor = theme?.muted ?? Colors.grey.shade200;
    final mutedFg = theme?.mutedForeground ?? Colors.grey;

    if (stats.isEmpty) return const SizedBox.shrink();

    final maxValue = stats.map((s) => s.value).fold<num>(0, (a, b) => a > b ? a : b);
    final displayMax = maxValue < 1 ? 1.0 : maxValue.toDouble();

    return SizedBox(
      height: 140,
      child: BarChart(
        BarChartData(
          maxY: displayMax * 1.2,
          minY: 0,
          gridData: FlGridData(
            drawVerticalLine: false,
            horizontalInterval: displayMax > 1 ? displayMax / 3 : 1,
            getDrawingHorizontalLine: (_) => FlLine(
              color: mutedColor,
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            topTitles: const AxisTitles(),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= stats.length) return const SizedBox.shrink();
                  final weekday = stats[index].date.weekday - 1; // 0=Lun
                  return Text(
                    _dayLabels[weekday],
                    style: TextStyle(fontSize: 11, color: mutedFg),
                  );
                },
              ),
            ),
          ),
          barGroups: List.generate(stats.length, (i) {
            final s = stats[i];
            final hasValue = s.value > 0;
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: hasValue ? s.value.toDouble() : 0,
                  color: hasValue ? primaryColor : mutedColor,
                  width: 18,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ],
            );
          }),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => Theme.of(context).colorScheme.surface,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final s = stats[groupIndex];
                if (s.value <= 0) return null;
                return BarTooltipItem(
                  s.value % 1 == 0
                      ? s.value.toInt().toString()
                      : s.value.toStringAsFixed(1),
                  TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
