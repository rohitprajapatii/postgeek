import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../core/theme/app_colors.dart';

class QueryStatsChart extends StatelessWidget {
  final Map<String, dynamic> queryStats;

  const QueryStatsChart({
    super.key,
    required this.queryStats,
  });

  @override
  Widget build(BuildContext context) {
    // Extract data
    final totalCalls = double.tryParse(queryStats['total_calls']?.toString() ?? '0') ?? 0;
    final totalExecTime = double.tryParse(queryStats['total_exec_time_ms']?.toString() ?? '0') ?? 0;
    final avgQueryTime = double.tryParse(queryStats['avg_query_time_ms']?.toString() ?? '0') ?? 0;
    final totalRows = double.tryParse(queryStats['total_rows']?.toString() ?? '0') ?? 0;
    final cacheHitRatio = double.tryParse(queryStats['cache_hit_ratio']?.toString() ?? '0') ?? 0;
    
    // Create some demo data points for a bar chart
    // In a real app, this would come from historical data
    final List<BarChartGroupData> barGroups = [
      _makeGroupData(0, avgQueryTime, 'Avg Time'),
      _makeGroupData(1, totalCalls / 1000, 'Calls (K)'),
      _makeGroupData(2, totalExecTime / 1000, 'Total Time (s)'),
      _makeGroupData(3, totalRows / 1000, 'Rows (K)'),
      _makeGroupData(4, cacheHitRatio, 'Cache Hit %'),
    ];
    
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: _getMaxY(barGroups),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: AppColors.tooltipBackground,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              String label;
              switch (groupIndex) {
                case 0:
                  label = '${avgQueryTime.toStringAsFixed(2)} ms';
                  break;
                case 1:
                  label = '${totalCalls.toInt()} calls';
                  break;
                case 2:
                  label = '${(totalExecTime / 1000).toStringAsFixed(2)} s';
                  break;
                case 3:
                  label = '${totalRows.toInt()} rows';
                  break;
                case 4:
                  label = '${cacheHitRatio.toStringAsFixed(2)}%';
                  break;
                default:
                  label = '';
              }
              return BarTooltipItem(
                label,
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                String text;
                switch (value.toInt()) {
                  case 0:
                    text = 'Avg Time';
                    break;
                  case 1:
                    text = 'Calls';
                    break;
                  case 2:
                    text = 'Total Time';
                    break;
                  case 3:
                    text = 'Rows';
                    break;
                  case 4:
                    text = 'Cache Hit';
                    break;
                  default:
                    text = '';
                }
                
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(
                    text,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: AppColors.divider),
        ),
        gridData: FlGridData(
          show: true,
          horizontalInterval: _getMaxY(barGroups) / 5,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: AppColors.divider,
              strokeWidth: 1,
            );
          },
        ),
        barGroups: barGroups,
      ),
    );
  }

  BarChartGroupData _makeGroupData(int x, double y, String label) {
    Color color;
    switch (x) {
      case 0:
        color = AppColors.primary;
        break;
      case 1:
        color = AppColors.secondary;
        break;
      case 2:
        color = AppColors.info;
        break;
      case 3:
        color = AppColors.warning;
        break;
      case 4:
        color = AppColors.success;
        break;
      default:
        color = AppColors.primary;
    }
    
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 22,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(4),
          ),
        ),
      ],
    );
  }

  double _getMaxY(List<BarChartGroupData> barGroups) {
    double maxY = 0;
    for (var group in barGroups) {
      for (var rod in group.barRods) {
        if (rod.toY > maxY) {
          maxY = rod.toY;
        }
      }
    }
    return maxY * 1.2; // Add 20% padding
  }
}