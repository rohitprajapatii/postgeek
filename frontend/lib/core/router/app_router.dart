import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/connection/screens/connection_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/queries/screens/queries_screen.dart';
import '../../features/activity/screens/activity_screen.dart';
import '../../features/health/screens/health_screen.dart';
import '../widgets/app_scaffold.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/',
    routes: [
      ShellRoute(
        builder: (context, state, child) {
          return AppScaffold(child: child);
        },
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (context, state) => NoTransitionPage(
              child: ConnectionScreen(),
            ),
          ),
          GoRoute(
            path: '/dashboard',
            pageBuilder: (context, state) => NoTransitionPage(
              child: DashboardScreen(),
            ),
          ),
          GoRoute(
            path: '/queries',
            pageBuilder: (context, state) => NoTransitionPage(
              child: QueriesScreen(),
            ),
          ),
          GoRoute(
            path: '/activity',
            pageBuilder: (context, state) => NoTransitionPage(
              child: ActivityScreen(),
            ),
          ),
          GoRoute(
            path: '/health',
            pageBuilder: (context, state) => NoTransitionPage(
              child: HealthScreen(),
            ),
          ),
        ],
      ),
    ],
  );
}