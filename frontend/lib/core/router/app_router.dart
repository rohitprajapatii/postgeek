import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/connection/screens/connection_screen.dart';
import '../../features/connection/bloc/connection_bloc.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/queries/screens/queries_screen.dart';
import '../../features/activity/screens/activity_screen.dart';
import '../../features/health/screens/health_screen.dart';
import '../../features/data_management/screens/data_management_screen.dart';
import '../widgets/app_scaffold.dart';

class AppRouter {
  static GoRouter createRouter(ConnectionBloc connectionBloc) {
    return GoRouter(
      initialLocation: '/',
      redirect: (context, state) {
        final isConnected =
            connectionBloc.state.status == ConnectionStatus.connected;
        final isOnConnectionScreen = state.uri.path == '/';

        // If not connected and trying to access protected routes, redirect to connection screen
        if (!isConnected && !isOnConnectionScreen) {
          return '/';
        }

        // If connected and on connection screen, redirect to dashboard
        if (isConnected && isOnConnectionScreen) {
          return '/dashboard';
        }

        return null; // No redirect needed
      },
      refreshListenable: GoRouterRefreshStream(connectionBloc.stream),
      routes: [
        ShellRoute(
          builder: (context, state, child) {
            return AppScaffold(child: child);
          },
          routes: [
            GoRoute(
              path: '/',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: ConnectionScreen(),
              ),
            ),
            GoRoute(
              path: '/dashboard',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: DashboardScreen(),
              ),
            ),
            GoRoute(
              path: '/queries',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: QueriesScreen(),
              ),
            ),
            GoRoute(
              path: '/activity',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: ActivityScreen(),
              ),
            ),
            GoRoute(
              path: '/health',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: HealthScreen(),
              ),
            ),
            GoRoute(
              path: '/data-management',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: DataManagementScreen(),
              ),
            ),
          ],
        ),
      ],
    );
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
