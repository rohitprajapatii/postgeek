import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class LocksTable extends StatelessWidget {
  final List<dynamic> locks;

  const LocksTable({
    super.key,
    required this.locks,
  });

  @override
  Widget build(BuildContext context) {
    if (locks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.info_outline,
              color: AppColors.info,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'No locks found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ],
        ),
      );
    }

    // Group locks by granted status
    final grantedLocks = locks.where((lock) => lock['granted'] == true).toList();
    final pendingLocks = locks.where((lock) => lock['granted'] != true).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pending Locks (more important to show first)
          if (pendingLocks.isNotEmpty) ...[
            _buildLocksTable(
              context, 
              pendingLocks, 
              'Pending Locks', 
              AppColors.warning,
            ),
            const SizedBox(height: 24),
          ],
          
          // Granted Locks
          if (grantedLocks.isNotEmpty)
            _buildLocksTable(
              context, 
              grantedLocks, 
              'Granted Locks', 
              AppColors.success,
            ),
        ],
      ),
    );
  }

  Widget _buildLocksTable(
    BuildContext context, 
    List<dynamic> locksList, 
    String title,
    Color titleColor,
  ) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  locksList == locks.where((lock) => lock['granted'] != true).toList()
                      ? Icons.lock
                      : Icons.lock_open,
                  color: titleColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '$title (${locksList.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: titleColor,
                      ),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 16,
              headingRowColor: WidgetStateProperty.all(AppColors.chipBackground),
              columns: const [
                DataColumn(label: Text('PID')),
                DataColumn(label: Text('Lock Type')),
                DataColumn(label: Text('Mode')),
                DataColumn(label: Text('Relation')),
                DataColumn(label: Text('User')),
                DataColumn(label: Text('Application')),
                DataColumn(label: Text('Duration')),
                DataColumn(label: Text('Query')),
              ],
              rows: locksList.map((lock) {
                final pid = lock['pid'] ?? 'N/A';
                final lockType = lock['locktype'] ?? 'N/A';
                final mode = lock['mode'] ?? 'N/A';
                final relationName = lock['relation_name'] ?? 'N/A';
                final username = lock['username'] ?? 'N/A';
                final applicationName = lock['application_name'] ?? 'N/A';
                final queryDuration = lock['query_duration_seconds'] ?? 0;
                final query = lock['query'] ?? 'N/A';
                
                return DataRow(
                  cells: [
                    DataCell(Text(pid.toString())),
                    DataCell(Text(_formatLockType(lockType))),
                    DataCell(Text(_formatLockMode(mode))),
                    DataCell(Text(relationName.toString())),
                    DataCell(Text(username.toString())),
                    DataCell(Text(applicationName.toString())),
                    DataCell(Text('${queryDuration.toStringAsFixed(1)}s')),
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
        ],
      ),
    );
  }

  String _formatLockType(String lockType) {
    // Convert PostgreSQL lock type codes to readable names
    switch (lockType.toLowerCase()) {
      case 'relation':
        return 'Table';
      case 'tuple':
        return 'Row';
      case 'transactionid':
        return 'Transaction';
      case 'virtualxid':
        return 'Virtual Transaction';
      case 'object':
        return 'Database Object';
      case 'userlock':
        return 'User Lock';
      case 'advisory':
        return 'Advisory Lock';
      default:
        return lockType;
    }
  }

  String _formatLockMode(String mode) {
    // Convert PostgreSQL lock mode codes to readable names
    switch (mode.toLowerCase()) {
      case 'accesssharelock':
        return 'Access Share';
      case 'rowsharelock':
        return 'Row Share';
      case 'rowexclusivelock':
        return 'Row Exclusive';
      case 'shareupdateexclusivelock':
        return 'Share Update Exclusive';
      case 'sharelock':
        return 'Share';
      case 'sharerowexclusivelock':
        return 'Share Row Exclusive';
      case 'exclusivelock':
        return 'Exclusive';
      case 'accessexclusivelock':
        return 'Access Exclusive';
      default:
        return mode;
    }
  }
}