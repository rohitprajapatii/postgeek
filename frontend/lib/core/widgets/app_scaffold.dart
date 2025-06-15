import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/connection/bloc/connection_bloc.dart' as connection_bloc;
import '../theme/app_colors.dart';
import 'sidebar_navigation.dart';

class AppScaffold extends StatelessWidget {
  final Widget child;

  const AppScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          BlocBuilder<connection_bloc.ConnectionBloc,
              connection_bloc.ConnectionState>(
            builder: (context, state) {
              // Only show sidebar if connected
              if (state.status == connection_bloc.ConnectionStatus.connected) {
                return SidebarNavigation(
                  currentPath: GoRouterState.of(context).uri.path,
                );
              }
              return const SizedBox();
            },
          ),
          Expanded(
            child: Container(
              color: AppColors.background,
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}
