import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/connection/screens/connection_screen.dart';
import '../../features/connection/bloc/connection_bloc.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/queries/screens/queries_screen.dart';
import '../../features/activity/screens/activity_screen.dart';
import '../../features/health/screens/health_screen.dart';
import '../../features/data_management/screens/enhanced_data_management_screen.dart';
import '../widgets/app_scaffold.dart';

class AppRouter {
  static GoRouter createRouter(ConnectionBloc connectionBloc) {
    return GoRouter(
      initialLocation: '/',
      // Disable browser navigation history
      routerNeglect: true,
      redirect: (context, state) {
        final isConnected =
            connectionBloc.state.status == ConnectionStatus.connected;
        final isOnConnectionScreen = state.uri.path == '/';

        if (kDebugMode) {
          print(
              'Router redirect - isConnected: $isConnected, currentPath: ${state.uri.path}');
        }

        // Only redirect if not connected and trying to access protected routes
        if (!isConnected && !isOnConnectionScreen) {
          return '/';
        }

        // No automatic redirects for connected users - prevents unwanted navigation
        return null;
      },
      refreshListenable: GoRouterRefreshStream(connectionBloc.stream),
      routes: [
        // Connection screen - accessible only when not connected
        GoRoute(
          path: '/',
          pageBuilder: (context, state) {
            final isConnected =
                connectionBloc.state.status == ConnectionStatus.connected;

            // If already connected, manually navigate to dashboard
            if (isConnected) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _navigateWithStackClear(context, '/dashboard');
              });

              // Return a temporary loading screen while navigating
              return const NoTransitionPage(
                child: Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              );
            }

            return const NoTransitionPage(
              child: ConnectionScreen(),
            );
          },
        ),

        // Dashboard screen
        GoRoute(
          path: '/dashboard',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: AppScaffold(
              child: DashboardScreen(),
            ),
          ),
        ),

        // Queries screen
        GoRoute(
          path: '/queries',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: AppScaffold(
              child: QueriesScreen(),
            ),
          ),
        ),

        // Activity screen
        GoRoute(
          path: '/activity',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: AppScaffold(
              child: ActivityScreen(),
            ),
          ),
        ),

        // Health screen
        GoRoute(
          path: '/health',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: AppScaffold(
              child: HealthScreen(),
            ),
          ),
        ),

        // Data Management screen
        GoRoute(
          path: '/data-management',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: AppScaffold(
              child: EnhancedDataManagementScreen(),
            ),
          ),
        ),
      ],
    );
  }

  // Helper method to navigate with stack clearing
  static void _navigateWithStackClear(BuildContext context, String path) {
    // Use Router.neglect to prevent browser history tracking
    Router.neglect(context, () {
      context.go(path);
    });

    if (kDebugMode) {
      print('Navigating to $path with stack clear and no browser history');
    }
  }
}

// Extension to add navigation helpers
extension AppRouterExtension on BuildContext {
  /// Navigate to a path ensuring single-screen navigation (no stack buildup)
  void navigateToScreen(String path) {
    // Use Router.neglect to prevent browser history tracking
    Router.neglect(this, () {
      go(path);
    });

    if (kDebugMode) {
      print('Single-screen navigation to: $path (no browser history)');
    }
  }
}

// Helper class to make GoRouter listen to BLoC stream changes
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
          (dynamic _) => notifyListeners(),
        );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
