import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class MissingIndexesCard extends StatelessWidget {
  final List<dynamic> indexes;

  const MissingIndexesCard({
    super.key,
    required this.indexes,
  });

  @override
  Widget build(BuildContext context) {
    if (indexes.isEmpty) {
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
                'No missing indexes detected',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Your tables appear to have appropriate indexes for the current query patterns.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

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
                  'Potential Missing Indexes (${indexes.length})',
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
              'The following tables are experiencing sequential scans that could potentially benefit from indexes:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 16,
              headingRowColor: WidgetStateProperty.all(AppColors.chipBackground),
              columns: const [
                DataColumn(label: Text('Table')),
                DataColumn(label: Text('Sequential Scans')),
                DataColumn(label: Text('Index Scans')),
                DataColumn(label: Text('Rows Read')),
                DataColumn(label: Text('Avg Rows Per Scan')),
                DataColumn(label: Text('Estimated Total Rows')),
              ],
              rows: indexes.map((index) {
                final schema = index['schema'] ?? 'public';
                final tableName = index['table_name'] ?? 'Unknown';
                final sequentialScans = index['sequential_scans'] ?? 0;
                final indexScans = index['index_scans'] ?? 0;
                final rowsRead = index['rows_sequential_read'] ?? 0;
                final avgRows = index['avg_rows_per_scan'] ?? 0;
                final estimatedRows = index['estimated_rows'] ?? 0;
                
                return DataRow(
                  cells: [
                    DataCell(Text('$schema.$tableName')),
                    DataCell(Text(sequentialScans.toString())),
                    DataCell(Text(indexScans.toString())),
                    DataCell(Text(rowsRead.toString())),
                    DataCell(Text(avgRows.toString())),
                    DataCell(Text(estimatedRows.toString())),
                  ],
                );
              }).toList(),
            ),
          ),
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
                    'Consider adding indexes on columns used in WHERE clauses for these tables. '
                    'Use EXPLAIN ANALYZE to identify the specific columns that would benefit most from indexing.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Example: CREATE INDEX idx_table_column ON schema.table(column);',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontFamily: 'Fira Code',
                          fontSize: 12,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}