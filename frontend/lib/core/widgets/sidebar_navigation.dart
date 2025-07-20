import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/connection/bloc/connection_bloc.dart' as connection_bloc;
import '../theme/app_colors.dart';
import '../router/app_router.dart';

class SidebarNavigation extends StatelessWidget {
  final String currentPath;

  const SidebarNavigation({
    super.key,
    required this.currentPath,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      color: AppColors.surface,
      child: Column(
        children: [
          // App Logo and Title
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Row(
              children: [
                const Icon(
                  Icons.data_usage,
                  color: AppColors.primary,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Text(
                  'PostGeek',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
          const Divider(),
          // Navigation Links
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildNavItem(
                  context,
                  'Dashboard',
                  Icons.dashboard,
                  '/dashboard',
                ),
                _buildNavItem(
                  context,
                  'Queries',
                  Icons.query_stats,
                  '/queries',
                ),
                _buildNavItem(
                  context,
                  'Activity',
                  Icons.account_tree,
                  '/activity',
                ),
                _buildNavItem(
                  context,
                  'Health',
                  Icons.health_and_safety,
                  '/health',
                ),
                _buildNavItem(
                  context,
                  'Data Studio',
                  Icons.table_view,
                  '/data-management',
                ),
              ],
            ),
          ),
          const Divider(),
          // Connection Info
          Container(
            padding: const EdgeInsets.all(16),
            child: BlocBuilder<connection_bloc.ConnectionBloc,
                connection_bloc.ConnectionState>(
              builder: (context, state) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Connected',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      state.connectionInfo?.database ?? 'Unknown',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      state.connectionInfo?.host ?? 'Unknown',
                      style: Theme.of(context).textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.logout, size: 16),
                        label: const Text('Disconnect'),
                        onPressed: () {
                          _showDisconnectConfirmation(context);
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    String title,
    IconData icon,
    String path,
  ) {
    final isActive = currentPath == path;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color:
            isActive ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isActive ? AppColors.primary : AppColors.textSecondary,
          size: 20,
        ),
        title: Text(
          title,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isActive ? AppColors.primary : AppColors.textPrimary,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
        ),
        onTap: () {
          if (!isActive) {
            _navigateToPath(context, path);
          }
        },
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        dense: true,
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  /// Navigate to a path using single-stack navigation (replacement instead of push)
  void _navigateToPath(BuildContext context, String path) {
    // Use the custom extension to ensure single-screen navigation
    context.navigateToScreen(path);

    if (kIsWeb && kDebugMode) {
      print('Navigating to $path with route replacement');
    }
  }

  void _showDisconnectConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disconnect from Database'),
        content: const Text(
            'Are you sure you want to disconnect from the database? '
            'You will need to reconnect to continue using the application.'),
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
              context
                  .read<connection_bloc.ConnectionBloc>()
                  .add(connection_bloc.DisconnectRequested());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );
  }
}
