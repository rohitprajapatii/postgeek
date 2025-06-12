import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../core/theme/app_colors.dart';

class DatabaseMetricsChart extends StatelessWidget {
  final Map<String, dynamic> queryStats;

  const DatabaseMetricsChart({
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
    
    // For demo purposes, we'll create some sample data points for a time series
    // In a real app, you'd fetch historical data from your backend
    final List<FlSpot> queryTimeSpots = List.generate(
      10,
      (index) => FlSpot(index.toDouble(), avgQueryTime * (0.5 + index / 10)),
    );
    
    return Column(
      children: [
        // Tab selector for different charts (for future expansion)
        const SizedBox(height: 16),
        
        // Main chart
        Expanded(
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: true,
                getDrawingHorizontalLine: (value) {
                  return const FlLine(
                    color: AppColors.divider,
                    strokeWidth: 1,
                  );
                },
                getDrawingVerticalLine: (value) {
                  return const FlLine(
                    color: AppColors.divider,
                    strokeWidth: 1,
                  );
                },
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
                    reservedSize: 30,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      // For demo purposes, show time intervals
                      // In a real app, these would be actual timestamps
                      return SideTitleWidget(
                        axisSide: meta.axisSide,
                        child: Text(
                          '${value.toInt() * 10}m ago',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 10,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: avgQueryTime / 2,
                    getTitlesWidget: (value, meta) {
                      return SideTitleWidget(
                        axisSide: meta.axisSide,
                        child: Text(
                          '${value.toStringAsFixed(1)} ms',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 10,
                          ),
                        ),
                      );
                    },
                    reservedSize: 40,
                  ),
                ),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border.all(color: AppColors.divider),
              ),
              minX: 0,
              maxX: 9,
              minY: 0,
              maxY: avgQueryTime * 1.5,
              lineBarsData: [
                LineChartBarData(
                  spots: queryTimeSpots,
                  isCurved: true,
                  gradient: const LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.secondary,
                    ],
                  ),
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(
                    show: false,
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withOpacity(0.3),
                        AppColors.secondary.withOpacity(0.0),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Chart legend and metrics
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetricItem(
                context: context,
                label: 'Total Queries',
                value: totalCalls.toStringAsFixed(0),
                color: AppColors.primary,
              ),
              _buildMetricItem(
                context: context,
                label: 'Avg Query Time',
                value: '${avgQueryTime.toStringAsFixed(2)} ms',
                color: AppColors.secondary,
              ),
              _buildMetricItem(
                context: context,
                label: 'Cache Hit Ratio',
                value: '${cacheHitRatio.toStringAsFixed(2)}%',
                color: AppColors.success,
              ),
              _buildMetricItem(
                context: context,
                label: 'Total Rows',
                value: totalRows.toStringAsFixed(0),
                color: AppColors.info,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricItem({
    required BuildContext context,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
}