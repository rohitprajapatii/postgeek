import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../core/theme/app_colors.dart';

class BlockedQueriesTable extends StatelessWidget {
  final List<dynamic> blockedQueries;
  final Function(int) onTerminate;

  const BlockedQueriesTable({
    super.key,
    required this.blockedQueries,
    required this.onTerminate,
  });

  @override
  Widget build(BuildContext context) {
    if (blockedQueries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle,
              color: AppColors.success,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'No blocked queries',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'All queries are running without blocking issues',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: blockedQueries.length,
      itemBuilder: (context, index) {
        final blockingInfo = blockedQueries[index];
        return _buildBlockedQueryCard(context, blockingInfo);
      },
    );
  }

  Widget _buildBlockedQueryCard(BuildContext context, dynamic blockingInfo) {
    final blockedPid = blockingInfo['blocked_pid'] ?? 'N/A';
    final blockedUser = blockingInfo['blocked_user'] ?? 'N/A';
    final blockedApplication = blockingInfo['blocked_application'] ?? 'N/A';
    final blockedQuery = blockingInfo['blocked_query'] ?? 'N/A';
    final blockedDuration = blockingInfo['blocked_duration_seconds'] ?? 0;
    
    final blockingPid = blockingInfo['blocking_pid'] ?? 'N/A';
    final blockingUser = blockingInfo['blocking_user'] ?? 'N/A';
    final blockingApplication = blockingInfo['blocking_application'] ?? 'N/A';
    final blockingQuery = blockingInfo['blocking_query'] ?? 'N/A';
    final blockingDuration = blockingInfo['blocking_duration_seconds'] ?? 0;
    
    // Calculate duration texts
    final blockedStart = DateTime.now().subtract(
      Duration(seconds: blockedDuration.toInt()),
    );
    final blockedDurationText = timeago.format(blockedStart, allowFromNow: true);
    
    final blockingStart = DateTime.now().subtract(
      Duration(seconds: blockingDuration.toInt()),
    );
    final blockingDurationText = timeago.format(blockingStart, allowFromNow: true);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
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
                  'Blocking Issue',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.warning,
                      ),
                ),
              ],
            ),
          ),
          
          // Blocked Query
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.1),
              border: const Border(
                left: BorderSide(
                  color: AppColors.error,
                  width: 4,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Blocked Query (PID: $blockedPid)',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.error,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'User: $blockedUser, Application: $blockedApplication',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  'Waiting for: $blockedDurationText',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  width: double.infinity,
                  child: Text(
                    blockedQuery,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontFamily: 'Fira Code',
                        ),
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('Terminate Blocked Session'),
                  onPressed: () => onTerminate(blockedPid),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          
          // Blocking arrow
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: const Icon(
                Icons.arrow_upward,
                color: AppColors.textTertiary,
              ),
            ),
          ),
          
          // Blocking Query
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.1),
              border: const Border(
                left: BorderSide(
                  color: AppColors.warning,
                  width: 4,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Blocking Query (PID: $blockingPid)',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.warning,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'User: $blockingUser, Application: $blockingApplication',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  'Running for: $blockingDurationText',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  width: double.infinity,
                  child: Text(
                    blockingQuery,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontFamily: 'Fira Code',
                        ),
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('Terminate Blocking Session'),
                  onPressed: () => onTerminate(blockingPid),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.warning,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}