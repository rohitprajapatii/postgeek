import 'package:flutter/material.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';

import '../../../core/theme/app_colors.dart';

class QueryList extends StatelessWidget {
  final List<dynamic> queries;

  const QueryList({
    super.key,
    required this.queries,
  });

  @override
  Widget build(BuildContext context) {
    if (queries.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Text(
              'No queries found',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: queries.length,
      itemBuilder: (context, index) {
        final query = queries[index];
        return _buildQueryCard(context, query, index);
      },
    );
  }

  Widget _buildQueryCard(BuildContext context, dynamic query, int index) {
    final queryText = query['query'] ?? 'Unknown query';
    final totalTime = query['total_time_ms'] ?? 0;
    final avgTime = query['avg_time_ms'] ?? 0;
    final minTime = query['min_time_ms'] ?? 0;
    final maxTime = query['max_time_ms'] ?? 0;
    final calls = query['calls'] ?? 0;
    final rows = query['rows'] ?? 0;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        title: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  (index + 1).toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _getQueryPreview(queryText),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
        subtitle: Text(
          'Avg: ${avgTime.toStringAsFixed(2)} ms, Calls: $calls, Rows: $rows',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: Text(
          '${totalTime.toStringAsFixed(2)} ms',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.bold,
              ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Query metrics grid
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  childAspectRatio: 2.5,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildMetricTile(
                      context: context,
                      label: 'Total Time',
                      value: '${totalTime.toStringAsFixed(2)} ms',
                    ),
                    _buildMetricTile(
                      context: context,
                      label: 'Avg Time',
                      value: '${avgTime.toStringAsFixed(2)} ms',
                    ),
                    _buildMetricTile(
                      context: context,
                      label: 'Min Time',
                      value: '${minTime.toStringAsFixed(2)} ms',
                    ),
                    _buildMetricTile(
                      context: context,
                      label: 'Max Time',
                      value: '${maxTime.toStringAsFixed(2)} ms',
                    ),
                    _buildMetricTile(
                      context: context,
                      label: 'Calls',
                      value: calls.toString(),
                    ),
                    _buildMetricTile(
                      context: context,
                      label: 'Rows',
                      value: rows.toString(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // SQL code display
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: const Color(0xFF282C34),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: HighlightView(
                      _formatQuery(queryText),
                      language: 'sql',
                      theme: atomOneDarkTheme,
                      padding: const EdgeInsets.all(12),
                      textStyle: const TextStyle(
                        fontFamily: 'Fira Code',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                
                // Optimization suggestions
                const SizedBox(height: 16),
                const Text(
                  'Optimization Suggestions:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _buildSuggestion(
                  context: context,
                  suggestion: _generateOptimizationSuggestion(query),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required BuildContext context,
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ],
    );
  }

  Widget _buildSuggestion({
    required BuildContext context,
    required String suggestion,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.info.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.info.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lightbulb,
            color: AppColors.info,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              suggestion,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  String _getQueryPreview(String query) {
    // Get the first line of the query for the preview
    final firstLine = query.split('\n').first.trim();
    return firstLine.length > 60 ? '${firstLine.substring(0, 60)}...' : firstLine;
  }

  String _formatQuery(String query) {
    // Simple SQL formatting for display
    // In a real app, you'd use a more sophisticated SQL formatter
    return query
        .replaceAll(' FROM ', '\nFROM ')
        .replaceAll(' WHERE ', '\nWHERE ')
        .replaceAll(' AND ', '\nAND ')
        .replaceAll(' OR ', '\nOR ')
        .replaceAll(' GROUP BY ', '\nGROUP BY ')
        .replaceAll(' ORDER BY ', '\nORDER BY ')
        .replaceAll(' LIMIT ', '\nLIMIT ');
  }

  String _generateOptimizationSuggestion(dynamic query) {
    // This is a simplified example - in a real app, you'd have more sophisticated analysis
    final queryText = (query['query'] ?? '').toString().toLowerCase();
    final rowsPerCall = query['rows'] != null && query['calls'] != null && query['calls'] > 0
        ? query['rows'] / query['calls']
        : 0;
    
    if (queryText.contains('select *')) {
      return 'Consider selecting only the columns you need instead of using SELECT *. This can reduce I/O and improve performance.';
    } else if (!queryText.contains(' where ')) {
      return 'This query doesn\'t have a WHERE clause, which might return more rows than necessary. Consider adding filtering conditions.';
    } else if (queryText.contains(' like \'%')) {
      return 'The query uses a leading wildcard in a LIKE condition, which prevents the use of indexes. Consider using a different filtering approach if possible.';
    } else if (rowsPerCall > 1000) {
      return 'This query returns a large number of rows (${rowsPerCall.toInt()} per call). Consider adding LIMIT or additional filtering to reduce the result set size.';
    } else {
      return 'Consider adding indexes on columns used in WHERE, JOIN, ORDER BY, and GROUP BY clauses. Use EXPLAIN ANALYZE to identify bottlenecks.';
    }
  }
}