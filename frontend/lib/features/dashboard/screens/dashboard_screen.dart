import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../bloc/dashboard_bloc.dart';
import '../widgets/summary_card.dart';
import '../widgets/health_status_card.dart';
import '../widgets/slow_queries_card.dart';
import '../widgets/activity_overview_card.dart';
import '../widgets/database_metrics_chart.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    context.read<DashboardBloc>().add(LoadDashboardData());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          return CustomScrollView(
            slivers: [
              // App Bar
              SliverAppBar(
                title: const Text('Dashboard'),
                floating: true,
                actions: [
                  // Refresh Button
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Refresh data',
                    onPressed: () {
                      context
                          .read<DashboardBloc>()
                          .add(StartDashboardRefresh());
                    },
                  ),
                  const SizedBox(width: 16),
                ],
              ),

              // Last Updated Info
              if (state.dashboardData != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Text(
                      'Last updated: ${DateFormat.yMd().add_Hms().format(state.dashboardData!.lastUpdated)}',
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.right,
                    ),
                  ),
                ),

              // Loading Indicator
              if (state.status == DashboardStatus.loading &&
                  state.dashboardData == null)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              // Error Message
              else if (state.status == DashboardStatus.error)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: AppColors.error,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading dashboard data',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          state.errorMessage ?? 'Unknown error',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () {
                            context
                                .read<DashboardBloc>()
                                .add(LoadDashboardData());
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              // Dashboard Content
              else if (state.dashboardData != null)
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Summary Cards Row
                      GridView.count(
                        crossAxisCount: _getCardCount(context),
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.5,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          SummaryCard(
                            title: 'Database Size',
                            value:
                                state.dashboardData!.databaseOverview['size'] ??
                                    'Unknown',
                            icon: Icons.storage,
                            color: AppColors.primary,
                          ),
                          SummaryCard(
                            title: 'Cache Hit Ratio',
                            value:
                                '${_formatNumber(state.dashboardData!.databaseOverview['cache_hit_ratio'])}%',
                            icon: Icons.memory,
                            color: AppColors.secondary,
                          ),
                          SummaryCard(
                            title: 'Active Sessions',
                            value: state.dashboardData!.activeSessions.length
                                .toString(),
                            icon: Icons.people,
                            color: AppColors.info,
                          ),
                          SummaryCard(
                            title: 'Deadlocks',
                            value: state.dashboardData!
                                    .healthOverview['deadlocks']?['deadlocks']
                                    ?.toString() ??
                                '0',
                            icon: Icons.lock,
                            color: AppColors.warning,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Charts Section
                      Text(
                        'Database Metrics',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 300,
                        child: DatabaseMetricsChart(
                          queryStats: state.dashboardData!.queryStats,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Health Status
                      Text(
                        'Health Status',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      HealthStatusCard(
                        healthData: state.dashboardData!.healthOverview,
                      ),
                      const SizedBox(height: 24),

                      // Slow Queries
                      Text(
                        'Slow Queries',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      SlowQueriesCard(
                        queries: state.dashboardData!.slowQueries,
                      ),
                      const SizedBox(height: 24),

                      // Activity Overview
                      Text(
                        'Activity Overview',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      ActivityOverviewCard(
                        activities: state.dashboardData!.activeSessions,
                      ),
                      const SizedBox(height: 24),
                    ]),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  int _getCardCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) return 1;
    if (width < 900) return 2;
    if (width < 1200) return 3;
    return 4;
  }

  String _formatNumber(dynamic value) {
    if (value == null) {
      return 'Unknown';
    }

    if (value is num) {
      return value.toStringAsFixed(2);
    }

    if (value is String) {
      final number = double.tryParse(value);
      if (number != null) {
        return number.toStringAsFixed(2);
      }
      return value;
    }

    return value.toString();
  }
}
