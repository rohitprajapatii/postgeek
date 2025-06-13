import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../bloc/queries_bloc.dart';
import '../widgets/query_stats_chart.dart';
import '../widgets/query_list.dart';
import '../widgets/query_types_chart.dart';

class QueriesScreen extends StatefulWidget {
  const QueriesScreen({super.key});

  @override
  State<QueriesScreen> createState() => _QueriesScreenState();
}

class _QueriesScreenState extends State<QueriesScreen> {
  @override
  void initState() {
    super.initState();
    context.read<QueriesBloc>().add(const LoadQueries());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<QueriesBloc, QueriesState>(
        builder: (context, state) {
          return CustomScrollView(
            slivers: [
              // App Bar
              SliverAppBar(
                title: const Text('Query Analysis'),
                floating: true,
                actions: [
                  // Reset Stats Button
                  TextButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reset Stats'),
                    onPressed: () {
                      _showResetConfirmation(context);
                    },
                  ),
                  // Refresh Button
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Refresh data',
                    onPressed: () {
                      context.read<QueriesBloc>().add(const LoadQueries());
                    },
                  ),
                  const SizedBox(width: 16),
                ],
              ),

              // Last Updated Info
              if (state.queryData != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Text(
                      'Last updated: ${DateFormat.yMd().add_Hms().format(state.queryData!.lastUpdated)}',
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.right,
                    ),
                  ),
                ),

              // Loading Indicator
              if (state.status == QueriesStatus.loading &&
                  state.queryData == null)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              // Error Message
              else if (state.status == QueriesStatus.error)
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
                          'Error loading query data',
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
                                .read<QueriesBloc>()
                                .add(const LoadQueries());
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              // Query Data Content
              else if (state.queryData != null)
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Query Stats Section
                      Text(
                        'Query Statistics',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 300,
                        child: QueryStatsChart(
                          queryStats: state.queryData!.queryStats,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Query Types Distribution
                      Text(
                        'Query Types Distribution',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 300,
                        child: QueryTypesChart(
                          queryTypes: state.queryData!.queryTypes,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Slow Queries List
                      Text(
                        'Slow Queries',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      QueryList(
                        queries: state.queryData!.slowQueries,
                      ),
                    ]),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  void _showResetConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Query Statistics'),
        content: const Text(
            'This will reset all query statistics in pg_stat_statements. '
            'This operation cannot be undone. Do you want to continue?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<QueriesBloc>().add(ResetQueryStats());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}
