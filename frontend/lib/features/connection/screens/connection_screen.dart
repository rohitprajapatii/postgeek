import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../bloc/connection_bloc.dart' as connection_bloc;
import '../widgets/connection_form.dart';

class ConnectionScreen extends StatelessWidget {
  const ConnectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<connection_bloc.ConnectionBloc,
          connection_bloc.ConnectionState>(
        listener: (context, state) {
          if (state.status == connection_bloc.ConnectionStatus.connected) {
            // Clear the navigation stack and go to dashboard
            // This ensures no back navigation to connection screen is possible
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.navigateToScreen('/dashboard');
            });
          }

          if (state.status == connection_bloc.ConnectionStatus.error &&
              state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: AppColors.error,
              ),
            );
          }

          // Handle disconnected state - reset any pending states
          if (state.status == connection_bloc.ConnectionStatus.disconnected) {
            // Clear any existing snackbars
            ScaffoldMessenger.of(context).clearSnackBars();
            // Reset connection state to initial for clean UI
            context
                .read<connection_bloc.ConnectionBloc>()
                .add(connection_bloc.ResetConnection());
          }
        },
        builder: (context, state) {
          return Center(
            child: Container(
              width: 450,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo and Title
                  const Icon(
                    Icons.data_usage,
                    color: AppColors.primary,
                    size: 56,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'PostGeek',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'PostgreSQL Monitoring Tool',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 32),

                  // Connection Form
                  ConnectionForm(
                    isConnecting: state.status ==
                        connection_bloc.ConnectionStatus.connecting,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
