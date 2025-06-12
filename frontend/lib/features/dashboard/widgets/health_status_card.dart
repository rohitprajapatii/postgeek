import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class HealthStatusCard extends StatelessWidget {
  final Map<String, dynamic> healthData;

  const HealthStatusCard({
    super.key,
    required this.healthData,
  });

  @override
  Widget build(BuildContext context) {
    final vacuumStatus = healthData['vacuum_status'] as List?;
    final connections = healthData['connection_count'] as Map<String, dynamic>?;
    final cacheHitRatio =
        healthData['cache_hit_ratio'] as Map<String, dynamic>?;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Connection Status
            _buildStatusIndicator(
              context: context,
              title: 'Database Connection',
              status: 'Connected',
              isHealthy: true,
              icon: Icons.link,
            ),
            const SizedBox(height: 16),

            // Cache Hit Ratio
            if (cacheHitRatio != null) ...[
              _buildStatusIndicator(
                context: context,
                title: 'Cache Hit Ratio',
                status:
                    '${((double.tryParse(cacheHitRatio['ratio'].toString()) ?? 0) * 100).toStringAsFixed(2)}%',
                isHealthy:
                    (double.tryParse(cacheHitRatio['ratio'].toString()) ?? 0) >
                        0.8,
                icon: Icons.memory,
              ),
              const SizedBox(height: 16),
            ],

            // Connection Usage
            if (connections != null) ...[
              _buildStatusIndicator(
                context: context,
                title: 'Connection Usage',
                status:
                    '${connections['used']} of ${connections['max_conn']} (${connections['free']} free)',
                isHealthy:
                    (int.tryParse(connections['free'].toString()) ?? 0) > 10,
                icon: Icons.people,
              ),
              const SizedBox(height: 16),
            ],

            // Vacuum Status
            if (vacuumStatus != null && vacuumStatus.isNotEmpty) ...[
              _buildStatusIndicator(
                context: context,
                title: 'Tables Requiring Vacuum',
                status: '${vacuumStatus.length} tables with dead tuples',
                isHealthy: vacuumStatus.length < 3,
                icon: Icons.cleaning_services,
              ),
              const SizedBox(height: 8),
              ...vacuumStatus
                  .take(3)
                  .map((table) => _buildVacuumTableRow(context, table)),
              if (vacuumStatus.length > 3)
                Padding(
                  padding: const EdgeInsets.only(left: 32, top: 4),
                  child: Text(
                    '... and ${vacuumStatus.length - 3} more tables',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIndicator({
    required BuildContext context,
    required String title,
    required String status,
    required bool isHealthy,
    required IconData icon,
  }) {
    final color = isHealthy ? AppColors.success : AppColors.warning;

    return Row(
      children: [
        Icon(
          icon,
          color: color,
          size: 20,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                status,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: color,
                    ),
              ),
            ],
          ),
        ),
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }

  Widget _buildVacuumTableRow(BuildContext context, dynamic tableData) {
    final tableName = tableData['table_name'] ?? 'Unknown';
    final deadTuples = tableData['dead_tuples'] ?? 0;
    final deadTuplesRatio = tableData['dead_tuples_ratio'] ?? 0;

    return Padding(
      padding: const EdgeInsets.only(left: 32, top: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              tableName,
              style: Theme.of(context).textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$deadTuples dead tuples ($deadTuplesRatio%)',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: (double.tryParse(deadTuplesRatio.toString()) ?? 0) > 20
                      ? AppColors.warning
                      : AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}
