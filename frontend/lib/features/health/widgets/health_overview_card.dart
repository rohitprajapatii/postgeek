import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../../../core/theme/app_colors.dart';

class HealthOverviewCard extends StatelessWidget {
  final Map<String, dynamic> healthData;

  const HealthOverviewCard({
    super.key,
    required this.healthData,
  });

  @override
  Widget build(BuildContext context) {
    // Extract data for metrics
    final vacuumStatus = healthData['vacuum_status'] as List?;
    final connections = healthData['connection_count'] as Map<String, dynamic>?;
    final cacheHitRatio = healthData['cache_hit_ratio'] as Map<String, dynamic>?;
    final databaseSize = healthData['database_size'] as Map<String, dynamic>?;
    
    // Calculate health score (simple algorithm, would be more complex in real app)
    int healthScore = 100;
    List<String> healthIssues = [];
    
    if (vacuumStatus != null && vacuumStatus.isNotEmpty) {
      healthScore -= vacuumStatus.length * 5;
      healthIssues.add('${vacuumStatus.length} tables need VACUUM');
    }
    
    if (cacheHitRatio != null) {
      final ratio = double.tryParse(cacheHitRatio['ratio'].toString()) ?? 0;
      if (ratio < 0.9) {
        healthScore -= (90 - (ratio * 100)).round();
        healthIssues.add('Low cache hit ratio (${(ratio * 100).toStringAsFixed(2)}%)');
      }
    }
    
    if (connections != null) {
      final used = int.tryParse(connections['used'].toString()) ?? 0;
      final max = int.tryParse(connections['max_conn'].toString()) ?? 0;
      if (max > 0 && used / max > 0.8) {
        healthScore -= ((used / max) * 100 - 80).round();
        healthIssues.add('High connection usage (${used}/${max})');
      }
    }
    
    // Ensure health score is between 0 and 100
    healthScore = healthScore.clamp(0, 100);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Health Score Section
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Health gauge
                SizedBox(
                  height: 150,
                  width: 150,
                  child: _buildHealthGauge(healthScore),
                ),
                const SizedBox(width: 16),
                
                // Health issues and metrics
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Health Score',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      if (healthIssues.isEmpty)
                        Row(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: AppColors.success,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'No health issues detected',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.success,
                                  ),
                            ),
                          ],
                        )
                      else
                        ...healthIssues.map((issue) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.warning,
                                  color: AppColors.warning,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    issue,
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: AppColors.warning,
                                        ),
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
            ),
            const SizedBox(height: 24),
            
            // Key Metrics Grid
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              childAspectRatio: 2.5,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildMetricItem(
                  context: context,
                  label: 'Database Size',
                  value: databaseSize?['pretty_size'] ?? 'Unknown',
                  icon: Icons.storage,
                  color: AppColors.primary,
                ),
                _buildMetricItem(
                  context: context,
                  label: 'Cache Hit Ratio',
                  value: cacheHitRatio != null
                      ? '${(double.tryParse(cacheHitRatio['ratio'].toString()) ?? 0 * 100).toStringAsFixed(2)}%'
                      : 'Unknown',
                  icon: Icons.memory,
                  color: _getCacheHitColor(cacheHitRatio),
                ),
                _buildMetricItem(
                  context: context,
                  label: 'Connection Usage',
                  value: connections != null
                      ? '${connections['used']}/${connections['max_conn']}'
                      : 'Unknown',
                  icon: Icons.people,
                  color: _getConnectionColor(connections),
                ),
                _buildMetricItem(
                  context: context,
                  label: 'Tables Needing VACUUM',
                  value: vacuumStatus?.length.toString() ?? '0',
                  icon: Icons.cleaning_services,
                  color: _getVacuumColor(vacuumStatus),
                ),
                _buildMetricItem(
                  context: context,
                  label: 'Deadlocks',
                  value: healthData['deadlocks']?['deadlocks']?.toString() ?? '0',
                  icon: Icons.lock,
                  color: AppColors.success,
                ),
                _buildMetricItem(
                  context: context,
                  label: 'Replication',
                  value: (healthData['replication'] is List && (healthData['replication'] as List).isNotEmpty)
                      ? 'Active'
                      : 'Not configured',
                  icon: Icons.sync,
                  color: AppColors.info,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthGauge(int score) {
    return SfRadialGauge(
      axes: <RadialAxis>[
        RadialAxis(
          minimum: 0,
          maximum: 100,
          showLabels: false,
          showTicks: false,
          axisLineStyle: const AxisLineStyle(
            thickness: 0.1,
            cornerStyle: CornerStyle.bothCurve,
            color: AppColors.divider,
            thicknessUnit: GaugeSizeUnit.factor,
          ),
          pointers: <GaugePointer>[
            RangePointer(
              value: score.toDouble(),
              width: 0.1,
              sizeUnit: GaugeSizeUnit.factor,
              cornerStyle: CornerStyle.bothCurve,
              gradient: SweepGradient(
                colors: <Color>[
                  AppColors.error,
                  AppColors.warning,
                  AppColors.success,
                ],
                stops: const <double>[0.0, 0.5, 1.0],
              ),
            ),
          ],
          annotations: <GaugeAnnotation>[
            GaugeAnnotation(
              widget: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    score.toString(),
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Text(
                    'score',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              angle: 90,
              positionFactor: 0,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricItem({
    required BuildContext context,
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: color,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: color,
              ),
        ),
      ],
    );
  }

  Color _getCacheHitColor(Map<String, dynamic>? cacheHitRatio) {
    if (cacheHitRatio == null) return AppColors.textSecondary;
    
    final ratio = double.tryParse(cacheHitRatio['ratio'].toString()) ?? 0;
    if (ratio > 0.95) return AppColors.success;
    if (ratio > 0.8) return AppColors.info;
    if (ratio > 0.6) return AppColors.warning;
    return AppColors.error;
  }

  Color _getConnectionColor(Map<String, dynamic>? connections) {
    if (connections == null) return AppColors.textSecondary;
    
    final used = int.tryParse(connections['used'].toString()) ?? 0;
    final max = int.tryParse(connections['max_conn'].toString()) ?? 0;
    
    if (max == 0) return AppColors.textSecondary;
    
    final ratio = used / max;
    if (ratio < 0.5) return AppColors.success;
    if (ratio < 0.7) return AppColors.info;
    if (ratio < 0.9) return AppColors.warning;
    return AppColors.error;
  }

  Color _getVacuumColor(List? vacuumStatus) {
    if (vacuumStatus == null || vacuumStatus.isEmpty) return AppColors.success;
    if (vacuumStatus.length < 3) return AppColors.info;
    if (vacuumStatus.length < 10) return AppColors.warning;
    return AppColors.error;
  }
}