import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../core/theme/app_colors.dart';

class ActivityOverviewCard extends StatelessWidget {
  final List<dynamic> activities;

  const ActivityOverviewCard({
    super.key,
    required this.activities,
  });

  @override
  Widget build(BuildContext context) {
    if (activities.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Text(
              'No active sessions',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
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
            child: Text(
              'Active Sessions (${activities.length})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 16,
              headingRowColor:
                  WidgetStateProperty.all(AppColors.chipBackground),
              columns: const [
                DataColumn(label: Text('PID')),
                DataColumn(label: Text('User')),
                DataColumn(label: Text('Application')),
                DataColumn(label: Text('State')),
                DataColumn(label: Text('Duration')),
                DataColumn(label: Text('Query')),
              ],
              rows: activities.take(5).map((activity) {
                final pid = activity['pid'] ?? 'N/A';
                final username = activity['username'] ?? 'N/A';
                final application = activity['application_name'] ?? 'N/A';
                final state = activity['state'] ?? 'N/A';
                final durationSeconds = activity['query_duration_seconds'] ?? 0;
                final durationSecondsInt = _safeParseDuration(durationSeconds);
                final query = activity['query'] ?? 'N/A';

                // Calculate duration ago text
                final queryStart = DateTime.now().subtract(
                  Duration(seconds: durationSecondsInt),
                );
                final durationText =
                    timeago.format(queryStart, allowFromNow: true);

                return DataRow(
                  cells: [
                    DataCell(Text(pid.toString())),
                    DataCell(Text(username.toString())),
                    DataCell(Text(application.toString())),
                    DataCell(_buildStateChip(state.toString())),
                    DataCell(Text(durationText)),
                    DataCell(
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 300),
                        child: Text(
                          query.toString(),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
          if (activities.length > 5)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '... and ${activities.length - 5} more sessions',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStateChip(String state) {
    Color color;

    switch (state.toLowerCase()) {
      case 'active':
        color = AppColors.success;
        break;
      case 'idle':
        color = AppColors.info;
        break;
      case 'idle in transaction':
        color = AppColors.warning;
        break;
      case 'waiting':
        color = AppColors.secondary;
        break;
      default:
        color = AppColors.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        state,
        style: TextStyle(
          fontSize: 12,
          color: color,
        ),
      ),
    );
  }

  int _safeParseDuration(dynamic duration) {
    if (duration == null) {
      return 0;
    }

    if (duration is int) {
      return duration.abs(); // Use absolute value to handle negative durations
    }

    if (duration is double) {
      return duration.abs().round();
    }

    if (duration is String) {
      final parsed = double.tryParse(duration);
      if (parsed != null) {
        return parsed.abs().round();
      }
      return 0;
    }

    return 0;
  }
}
