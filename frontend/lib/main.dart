import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:responsive_framework/responsive_framework.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/connection/bloc/connection_bloc.dart';
import 'features/dashboard/bloc/dashboard_bloc.dart';
import 'features/queries/bloc/queries_bloc.dart';
import 'features/activity/bloc/activity_bloc.dart';
import 'features/health/bloc/health_bloc.dart';
import 'core/services/api_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PostGeekApp());
}

class PostGeekApp extends StatelessWidget {
  const PostGeekApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<ApiService>(
          create: (context) => ApiService(),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<ConnectionBloc>(
            create: (context) => ConnectionBloc(
              apiService: context.read<ApiService>(),
            ),
          ),
          BlocProvider<DashboardBloc>(
            create: (context) => DashboardBloc(
              apiService: context.read<ApiService>(),
              connectionBloc: context.read<ConnectionBloc>(),
            ),
          ),
          BlocProvider<QueriesBloc>(
            create: (context) => QueriesBloc(
              apiService: context.read<ApiService>(),
              connectionBloc: context.read<ConnectionBloc>(),
            ),
          ),
          BlocProvider<ActivityBloc>(
            create: (context) => ActivityBloc(
              apiService: context.read<ApiService>(),
              connectionBloc: context.read<ConnectionBloc>(),
            ),
          ),
          BlocProvider<HealthBloc>(
            create: (context) => HealthBloc(
              apiService: context.read<ApiService>(),
              connectionBloc: context.read<ConnectionBloc>(),
            ),
          ),
        ],
        child: Builder(
          builder: (context) {
            return MaterialApp.router(
              title: 'PostGeek',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.darkTheme,
              routerConfig:
                  AppRouter.createRouter(context.read<ConnectionBloc>()),
              builder: (context, child) => ResponsiveBreakpoints.builder(
                child: child!,
                breakpoints: [
                  const Breakpoint(start: 0, end: 600, name: MOBILE),
                  const Breakpoint(start: 601, end: 900, name: TABLET),
                  const Breakpoint(start: 901, end: 1200, name: DESKTOP),
                  const Breakpoint(
                      start: 1201, end: double.infinity, name: 'XL'),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
