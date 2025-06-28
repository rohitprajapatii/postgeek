import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../connection/bloc/connection_bloc.dart' as connection_bloc;
import '../bloc/data_management_bloc.dart';
import '../widgets/enhanced_schema_browser.dart';
import '../widgets/enhanced_table_viewer.dart';
import '../widgets/global_search_bar.dart';
import '../widgets/table_tab_bar.dart';

class EnhancedDataManagementScreen extends StatefulWidget {
  const EnhancedDataManagementScreen({super.key});

  @override
  State<EnhancedDataManagementScreen> createState() =>
      _EnhancedDataManagementScreenState();
}

class _EnhancedDataManagementScreenState
    extends State<EnhancedDataManagementScreen> {
  @override
  void initState() {
    super.initState();
    _checkConnectionAndLoadSchemas();
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
            context.go('/connection');
          } else if (connectionState.status ==
              connection_bloc.ConnectionStatus.connected) {
            context.read<DataManagementBloc>().add(const LoadSchemas());
          }
        },
        child: Scaffold(
          backgroundColor: AppColors.background,
          body: Column(
            children: [
              // Header with global search and connection status
              _buildHeader(),

              // Tab bar for open tables
              _buildTabBar(),

              // Main content area
              Expanded(
                child: Row(
                  children: [
                    // Left sidebar - Schema Browser
                    Container(
                      width: 280,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        border: Border(
                          right: BorderSide(
                            color: AppColors.border,
                            width: 1,
                          ),
                        ),
                      ),
                      child: const EnhancedSchemaBrowser(),
                    ),

                    // Main content - Table viewers
                    Expanded(
                      child: _buildMainContent(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(
            color: AppColors.border,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // App title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.storage,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'PostGeek Studio',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),

          const SizedBox(width: 24),

          // Global search
          const Expanded(
            child: GlobalSearchBar(),
          ),

          const SizedBox(width: 24),

          // Connection status and actions
          _buildConnectionStatus(),
        ],
      ),
    );
  }

  Widget _buildConnectionStatus() {
    return BlocBuilder<connection_bloc.ConnectionBloc,
        connection_bloc.ConnectionState>(
      builder: (context, connectionState) {
        return Row(
          children: [
            // Connection status indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: connectionState.status ==
                        connection_bloc.ConnectionStatus.connected
                    ? AppColors.success.withOpacity(0.1)
                    : AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: connectionState.status ==
                          connection_bloc.ConnectionStatus.connected
                      ? AppColors.success.withOpacity(0.3)
                      : AppColors.error.withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: connectionState.status ==
                              connection_bloc.ConnectionStatus.connected
                          ? AppColors.success
                          : AppColors.error,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    connectionState.status ==
                            connection_bloc.ConnectionStatus.connected
                        ? 'Connected'
                        : 'Disconnected',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: connectionState.status ==
                              connection_bloc.ConnectionStatus.connected
                          ? AppColors.success
                          : AppColors.error,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Refresh button
            IconButton(
              onPressed: () {
                context.read<DataManagementBloc>().add(const LoadSchemas());
              },
              icon: Icon(
                Icons.refresh,
                color: AppColors.textSecondary,
                size: 20,
              ),
              tooltip: 'Refresh schemas',
              style: IconButton.styleFrom(
                backgroundColor: AppColors.inputBackground,
                padding: const EdgeInsets.all(8),
                minimumSize: Size.zero,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTabBar() {
    return BlocBuilder<DataManagementBloc, DataManagementState>(
      builder: (context, state) {
        if (!state.hasOpenTabs) {
          return const SizedBox.shrink();
        }

        return Container(
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(
              bottom: BorderSide(
                color: AppColors.border,
                width: 1,
              ),
            ),
          ),
          child: TableTabBar(
            tabs: state.openTabs,
            activeTabId: state.activeTabId,
            onTabSelected: (tabId) {
              context.read<DataManagementBloc>().add(SwitchToTab(tabId));
            },
            onTabClosed: (tabId) {
              context.read<DataManagementBloc>().add(CloseTableTab(tabId));
            },
            onTabReorder: (oldIndex, newIndex) {
              context.read<DataManagementBloc>().add(
                    ReorderTabs(oldIndex: oldIndex, newIndex: newIndex),
                  );
            },
          ),
        );
      },
    );
  }

  Widget _buildMainContent() {
    return BlocBuilder<DataManagementBloc, DataManagementState>(
      builder: (context, state) {
        if (!state.hasOpenTabs) {
          return _buildEmptyState();
        }

        final activeTab = state.activeTab;
        if (activeTab == null) {
          return _buildEmptyState();
        }

        return EnhancedTableViewer(
          tab: activeTab,
          onRefresh: () {
            context
                .read<DataManagementBloc>()
                .add(RefreshTabData(activeTab.id));
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Container(
      color: AppColors.background,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.border,
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.table_view_outlined,
                size: 48,
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Welcome to PostGeek Studio',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select a table from the sidebar to start exploring your data',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Tip: Use Cmd+K to quickly search for tables',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
