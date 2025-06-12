import 'package:flutter/material.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';

import '../../../core/theme/app_colors.dart';

class SlowQueriesCard extends StatelessWidget {
  final List<dynamic> queries;

  const SlowQueriesCard({
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
              'No slow queries found',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int i = 0; i < queries.length; i++) ...[
              if (i > 0) const Divider(height: 32),
              _buildQueryItem(context, queries[i], i + 1),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQueryItem(BuildContext context, dynamic query, int index) {
    final queryText = query['query'] ?? 'Unknown query';
    final totalTime = query['total_time_ms'] ?? 0;
    final avgTime = query['avg_time_ms'] ?? 0;
    final calls = query['calls'] ?? 0;
    final rows = query['rows'] ?? 0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
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
                  index.toString(),
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
                'Slow Query #$index',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Text(
              '${totalTime.toStringAsFixed(2)} ms total',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        // Query metrics
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            _buildMetricChip(
              label: 'Avg Time',
              value: '${avgTime.toStringAsFixed(2)} ms',
            ),
            _buildMetricChip(
              label: 'Calls',
              value: calls.toString(),
            ),
            _buildMetricChip(
              label: 'Rows',
              value: rows.toString(),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
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
      ],
    );
  }

  Widget _buildMetricChip({
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.chipBackground,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          fontSize: 12,
        ),
      ),
    );
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
}