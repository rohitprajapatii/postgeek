import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../../../core/theme/app_colors.dart';

class TableBloatCard extends StatelessWidget {
  final List<dynamic> tables;

  const TableBloatCard({
    super.key,
    required this.tables,
  });

  @override
  Widget build(BuildContext context) {
    if (tables.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Icon(
                Icons.check_circle,
                color: AppColors.success,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'No significant table bloat detected',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Your tables appear to be efficiently packed without excessive bloat.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Prepare data for the chart
    final chartData = tables.take(5).map((table) {
      final tableName = table['table_name'] ?? 'Unknown';
      final bloatRatio = double.tryParse(table['bloat_ratio']?.toString() ?? '0') ?? 0;
      return TableBloatData(tableName, bloatRatio);
    }).toList();

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(
                  Icons.warning,
                  color: AppColors.warning,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Table Bloat (${tables.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.warning,
                      ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'The following tables have significant bloat that could be reclaimed:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 16),
          
          // Bloat Chart
          if (chartData.isNotEmpty)
            SizedBox(
              height: 250,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SfCartesianChart(
                  primaryXAxis: const CategoryAxis(
                    labelStyle: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  primaryYAxis: const NumericAxis(
                    minimum: 0,
                    maximum: 100,
                    labelFormat: '{value}%',
                    labelStyle: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  tooltipBehavior: TooltipBehavior(enable: true),
                  series: <CartesianSeries>[
                    BarSeries<TableBloatData, String>(
                      dataSource: chartData,
                      xValueMapper: (TableBloatData data, _) => data.tableName,
                      yValueMapper: (TableBloatData data, _) => data.bloatRatio,
                      name: 'Bloat Ratio',
                      pointColorMapper: (TableBloatData data, _) => _getBloatColor(data.bloatRatio),
                      dataLabelSettings: const DataLabelSettings(
                        isVisible: true,
                        labelAlignment: ChartDataLabelAlignment.outer,
                        textStyle: TextStyle(
                          fontSize: 12,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          // Table Details
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 16,
              headingRowColor: WidgetStateProperty.all(AppColors.chipBackground),
              columns: const [
                DataColumn(label: Text('Table')),
                DataColumn(label: Text('Size')),
                DataColumn(label: Text('Live Tuples')),
                DataColumn(label: Text('Dead Tuples')),
                DataColumn(label: Text('Dead Ratio')),
                DataColumn(label: Text('Bloat Ratio')),
              ],
              rows: tables.map((table) {
                final schema = table['schema'] ?? 'public';
                final tableName = table['table_name'] ?? 'Unknown';
                final liveTuples = table['live_tuples'] ?? 0;
                final deadTuples = table['dead_tuples'] ?? 0;
                final deadTuplesRatio = table['dead_tup_ratio'] ?? 0;
                final bloatRatio = table['bloat_ratio'] ?? 0;
                final tableSize = table['table_size'] ?? 'Unknown';
                
                return DataRow(
                  cells: [
                    DataCell(Text('$schema.$tableName')),
                    DataCell(Text(tableSize.toString())),
                    DataCell(Text(liveTuples.toString())),
                    DataCell(Text(deadTuples.toString())),
                    DataCell(Text('${deadTuplesRatio.toString()}%')),
                    DataCell(
                      Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: _getBloatColor(double.tryParse(bloatRatio.toString()) ?? 0),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text('${bloatRatio.toString()}%'),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
          
          // Recommendations
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.info.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.lightbulb,
                        color: AppColors.info,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Recommendations',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppColors.info,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Table bloat occurs when rows are updated or deleted but the space is not immediately reclaimed. '
                    'Consider running VACUUM FULL on these tables to reclaim space, but be aware that this operation '
                    'requires an exclusive lock on the table.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Example: VACUUM FULL schema.table_name;',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontFamily: 'Fira Code',
                          fontSize: 12,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'For less disruptive maintenance, consider adjusting autovacuum settings or running regular VACUUM (without FULL) more frequently.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getBloatColor(double bloatRatio) {
    if (bloatRatio < 20) return AppColors.success;
    if (bloatRatio < 40) return AppColors.info;
    if (bloatRatio < 60) return AppColors.warning;
    return AppColors.error;
  }
}

class TableBloatData {
  final String tableName;
  final double bloatRatio;

  TableBloatData(this.tableName, this.bloatRatio);
}