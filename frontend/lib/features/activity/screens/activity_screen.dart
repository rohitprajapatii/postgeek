import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../bloc/activity_bloc.dart';
import '../widgets/active_sessions_table.dart';
import '../widgets/idle_sessions_table.dart';
import '../widgets/locks_table.dart';
import '../widgets/blocked_queries_table.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ActivityBloc>().add(LoadActivity());
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        body: BlocConsumer<ActivityBloc, ActivityState>(
          listener: (context, state) {
            if (state.terminationMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.terminationMessage!),
                  backgroundColor: AppColors.success,
                ),
              );
            }

            if (state.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage!),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          },
          builder: (context, state) {
            return CustomScrollView(
              slivers: [
                // App Bar with Tabs
                SliverAppBar(
                  title: const Text('Database Activity'),
                  floating: true,
                  pinned: true,
                  actions: [
                    // Refresh Button
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Refresh data',
                      onPressed: () {
                        context.read<ActivityBloc>().add(LoadActivity());
                      },
                    ),
                    const SizedBox(width: 16),
                  ],
                  bottom: const TabBar(
                    tabs: [
                      Tab(text: 'Active Sessions'),
                      Tab(text: 'Idle Sessions'),
                      Tab(text: 'Locks'),
                      Tab(text: 'Blocked Queries'),
                    ],
                    isScrollable: true,
                  ),
                ),

                // Last Updated Info
                if (state.activityData != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: Text(
                        'Last updated: ${DateFormat.yMd().add_Hms().format(state.activityData!.lastUpdated)}',
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ),

                // Loading Indicator
                if (state.status == ActivityStatus.loading &&
                    state.activityData == null)
                  const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  )
                // Error Message
                else if (state.status == ActivityStatus.error &&
                    state.activityData == null)
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
                            'Error loading activity data',
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
                              context.read<ActivityBloc>().add(LoadActivity());
                            },
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                // Tab Content
                else if (state.activityData != null)
                  SliverFillRemaining(
                    child: TabBarView(
                      children: [
                        // Active Sessions Tab
                        ActiveSessionsTable(
                          sessions: state.activityData!.activeSessions,
                          onTerminate: (pid) {
                            _showTerminateConfirmation(context, pid);
                          },
                        ),

                        // Idle Sessions Tab
                        IdleSessionsTable(
                          sessions: state.activityData!.idleSessions,
                          onTerminate: (pid) {
                            _showTerminateConfirmation(context, pid);
                          },
                        ),

                        // Locks Tab
                        LocksTable(
                          locks: state.activityData!.locks,
                        ),

                        // Blocked Queries Tab
                        BlockedQueriesTable(
                          blockedQueries: state.activityData!.blockedQueries,
                          onTerminate: (pid) {
                            _showTerminateConfirmation(context, pid);
                          },
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showTerminateConfirmation(BuildContext context, int pid) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terminate Session'),
        content: Text('This will terminate the database session with PID $pid. '
            'Any unsaved work in this session will be lost. Do you want to continue?'),
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
              context.read<ActivityBloc>().add(TerminateSession(pid));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Terminate'),
          ),
        ],
      ),
    );
  }
}
