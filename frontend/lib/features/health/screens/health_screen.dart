import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../bloc/health_bloc.dart';
import '../widgets/health_overview_card.dart';
import '../widgets/missing_indexes_card.dart';
import '../widgets/unused_indexes_card.dart';
import '../widgets/table_bloat_card.dart';

class HealthScreen extends StatelessWidget {
  const HealthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<HealthBloc, HealthState>(
        builder: (context, state) {
          return CustomScrollView(
            slivers: [
              // App Bar
              SliverAppBar(
                title: const Text('Database Health'),
                floating: true,
                actions: [
                  // Refresh Button
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Refresh data',
                    onPressed: () {
                      context.read<HealthBloc>().add(LoadHealthData());
                    },
                  ),
                  const SizedBox(width: 16),
                ],
              ),
              
              // Last Updated Info
              if (state.healthData != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Text(
                      'Last updated: ${DateFormat.yMd().add_Hms().format(state.healthData!.lastUpdated)}',
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.right,
                    ),
                  ),
                ),
              
              // Loading Indicator
              if (state.status == HealthStatus.loading && state.healthData == null)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              // Error Message
              else if (state.status == HealthStatus.error)
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
                          'Error loading health data',
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
                            context.read<HealthBloc>().add(LoadHealthData());
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              // Health Data Content
              else if (state.healthData != null)
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Health Overview
                      Text(
                        'Health Overview',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      HealthOverviewCard(
                        healthData: state.healthData!.healthOverview,
                      ),
                      const SizedBox(height: 24),
                      
                      // Missing Indexes
                      Text(
                        'Missing Indexes',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      MissingIndexesCard(
                        indexes: state.healthData!.missingIndexes,
                      ),
                      const SizedBox(height: 24),
                      
                      // Unused Indexes
                      Text(
                        'Unused Indexes',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      UnusedIndexesCard(
                        indexes: state.healthData!.unusedIndexes,
                      ),
                      const SizedBox(height: 24),
                      
                      // Table Bloat
                      Text(
                        'Table Bloat',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      TableBloatCard(
                        tables: state.healthData!.tableBloat,
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
}