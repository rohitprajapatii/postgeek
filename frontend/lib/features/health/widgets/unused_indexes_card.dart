import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class UnusedIndexesCard extends StatelessWidget {
  final List<dynamic> indexes;

  const UnusedIndexesCard({
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
                'No unused indexes detected',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'All of your indexes appear to be used by queries.',
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
                  'Unused Indexes (${indexes.length})',
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
              'The following indexes have low usage and may be candidates for removal:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 16,
              headingRowColor: MaterialStateProperty.all(AppColors.chipBackground),
              columns: const [
                DataColumn(label: Text('Table')),
                DataColumn(label: Text('Index')),
                DataColumn(label: Text('Size')),
                DataColumn(label: Text('Scans')),
              ],
              rows: indexes.map((index) {
                final schema = index['schema'] ?? 'public';
                final tableName = index['table_name'] ?? 'Unknown';
                final indexName = index['index_name'] ?? 'Unknown';
                final indexSize = index['index_size'] ?? 'Unknown';
                final scans = index['index_scans'] ?? 0;
                
                return DataRow(
                  cells: [
                    DataCell(Text('$schema.$tableName')),
                    DataCell(Text(indexName)),
                    DataCell(Text(indexSize)),
                    DataCell(Text(scans.toString())),
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
                    'Unused indexes waste disk space and can slow down write operations. '
                    'Consider removing these indexes if they are not required for primary or foreign key constraints.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Example: DROP INDEX schema.index_name;',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontFamily: 'Fira Code',
                          fontSize: 12,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'WARNING: Verify that these indexes are truly unnecessary before removing them. Some indexes may be used infrequently but still be critical for certain operations.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.warning,
                          fontWeight: FontWeight.bold,
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