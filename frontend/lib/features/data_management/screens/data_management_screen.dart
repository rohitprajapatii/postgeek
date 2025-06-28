import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../connection/bloc/connection_bloc.dart' as connection_bloc;
import '../bloc/data_management_bloc.dart';
import '../widgets/schema_browser.dart';
import '../widgets/simple_data_table.dart';
import '../widgets/query_console.dart';

class DataManagementScreen extends StatefulWidget {
  const DataManagementScreen({super.key});

  @override
  State<DataManagementScreen> createState() => _DataManagementScreenState();
}

class _DataManagementScreenState extends State<DataManagementScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Check connection status before loading schemas
    _checkConnectionAndLoadSchemas();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _checkConnectionAndLoadSchemas() {
    final connectionState =
        context.read<connection_bloc.ConnectionBloc>().state;
    if (connectionState.status == connection_bloc.ConnectionStatus.connected) {
      context.read<DataManagementBloc>().add(const LoadSchemas());
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      child: BlocListener<connection_bloc.ConnectionBloc,
          connection_bloc.ConnectionState>(
        listener: (context, connectionState) {
          if (connectionState.status ==
              connection_bloc.ConnectionStatus.disconnected) {
            // Redirect to connection screen if disconnected
            context.go('/connection');
          } else if (connectionState.status ==
              connection_bloc.ConnectionStatus.connected) {
            // Load schemas when connected
            context.read<DataManagementBloc>().add(const LoadSchemas());
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                const Icon(Icons.storage, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text('Data Management Studio'),
                const Spacer(),
                // Connection status indicator
                BlocBuilder<connection_bloc.ConnectionBloc,
                    connection_bloc.ConnectionState>(
                  builder: (context, connectionState) {
                    if (connectionState.status ==
                        connection_bloc.ConnectionStatus.connected) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: AppColors.success.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle,
                                color: AppColors.success, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              'Connected',
                              style: TextStyle(
                                color: AppColors.success,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border:
                            Border.all(color: AppColors.error.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.error_outline,
                              color: AppColors.error, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            'Not Connected',
                            style: TextStyle(
                              color: AppColors.error,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    context.read<DataManagementBloc>().add(const LoadSchemas());
                  },
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Refresh'),
                  style: ElevatedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(
                  icon: Icon(Icons.folder_outlined),
                  text: 'Schema Browser',
                ),
                Tab(
                  icon: Icon(Icons.table_view_outlined),
                  text: 'Table Viewer',
                ),
                Tab(
                  icon: Icon(Icons.code_outlined),
                  text: 'Query Console',
                ),
              ],
            ),
          ),
          body: BlocListener<DataManagementBloc, DataManagementState>(
            listener: (context, state) {
              if (state.status == DataManagementStatus.error &&
                  state.errorMessage != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.errorMessage!),
                    backgroundColor: AppColors.error,
                    action: state.errorMessage!.contains('not connected')
                        ? SnackBarAction(
                            label: 'Connect',
                            onPressed: () => context.go('/connection'),
                          )
                        : null,
                  ),
                );
              }
            },
            child: TabBarView(
              controller: _tabController,
              children: [
                const SchemaBrowser(),
                _TableViewerTab(),
                const QueryConsole(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TableViewerTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DataManagementBloc, DataManagementState>(
      builder: (context, state) {
        if (state.selectedTableDetails == null) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.table_view_outlined, size: 64),
                SizedBox(height: 16),
                Text('Table Viewer'),
                Text('Select a table from Schema Browser to view its data'),
              ],
            ),
          );
        }

        if (state.status == DataManagementStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.tableData == null) {
          // Load table data
          final tableDetails = state.selectedTableDetails!;
          context.read<DataManagementBloc>().add(
                LoadTableData(
                  schemaName: tableDetails.schemaName,
                  tableName: tableDetails.tableName,
                ),
              );
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: [
            // Table Header
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${state.selectedTableDetails!.schemaName}.${state.selectedTableDetails!.tableName}',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        Text(
                          '${state.selectedTableDetails!.rowCount} rows • ${state.selectedTableDetails!.columns.length} columns',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      final tableDetails = state.selectedTableDetails!;
                      context.read<DataManagementBloc>().add(
                            LoadTableData(
                              schemaName: tableDetails.schemaName,
                              tableName: tableDetails.tableName,
                            ),
                          );
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh'),
                  ),
                ],
              ),
            ),
            // Data Table
            Expanded(
              child: SimpleDataTable(
                tableDetails: state.selectedTableDetails!,
                tableData: state.tableData!,
                onEditRecord: (record) {
                  // Handle edit record
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text('Edit functionality will be available soon'),
                    ),
                  );
                },
                onDeleteRecord: (record) {
                  // Handle delete record
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text('Delete functionality will be available soon'),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
