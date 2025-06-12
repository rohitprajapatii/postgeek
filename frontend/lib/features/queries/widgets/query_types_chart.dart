import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../core/theme/app_colors.dart';

class QueryTypesChart extends StatelessWidget {
  final List<dynamic> queryTypes;

  const QueryTypesChart({
    super.key,
    required this.queryTypes,
  });

  @override
  Widget build(BuildContext context) {
    // Create pie chart sections
    final sections = <PieChartSectionData>[];
    
    // Calculate total calls for percentage
    double totalCalls = 0;
    for (final type in queryTypes) {
      totalCalls += double.tryParse(type['total_calls']?.toString() ?? '0') ?? 0;
    }
    
    // Create sections
    for (int i = 0; i < queryTypes.length; i++) {
      final type = queryTypes[i];
      final queryType = type['query_type'] ?? 'Unknown';
      final calls = double.tryParse(type['total_calls']?.toString() ?? '0') ?? 0;
      final percentage = totalCalls > 0 ? (calls / totalCalls) * 100 : 0;
      
      sections.add(
        PieChartSectionData(
          value: calls,
          title: '$queryType\n${percentage.toStringAsFixed(1)}%',
          radius: 100,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          color: _getColorForQueryType(queryType),
        ),
      );
    }
    
    return Row(
      children: [
        // Pie Chart
        Expanded(
          flex: 3,
          child: PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 40,
              sectionsSpace: 2,
              pieTouchData: PieTouchData(
                touchCallback: (event, response) {},
              ),
            ),
          ),
        ),
        
        // Legend
        Expanded(
          flex: 2,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Query Type Distribution',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ...queryTypes.map((type) {
                final queryType = type['query_type'] ?? 'Unknown';
                final calls = double.tryParse(type['total_calls']?.toString() ?? '0') ?? 0;
                final totalTime = double.tryParse(type['total_time_ms']?.toString() ?? '0') ?? 0;
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _getColorForQueryType(queryType),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              queryType,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${calls.toInt()} calls, ${(totalTime / 1000).toStringAsFixed(2)}s total',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ],
    );
  }

  Color _getColorForQueryType(String queryType) {
    switch (queryType.toUpperCase()) {
      case 'SELECT':
        return AppColors.primary;
      case 'INSERT':
        return AppColors.success;
      case 'UPDATE':
        return AppColors.warning;
      case 'DELETE':
        return AppColors.error;
      default:
        return AppColors.secondary;
    }
  }
}