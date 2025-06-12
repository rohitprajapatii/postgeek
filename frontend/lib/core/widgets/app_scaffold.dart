import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/connection/bloc/connection_bloc.dart';
import '../theme/app_colors.dart';
import 'sidebar_navigation.dart';

class AppScaffold extends StatelessWidget {
  final Widget child;

  const AppScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<ConnectionBloc, ConnectionState>(
        listener: (context, state) {
          if (state.status == ConnectionStatus.disconnected && 
              GoRouterState.of(context).uri.path != '/') {
            context.go('/');
          }
        },
        child: Row(
          children: [
            BlocBuilder<ConnectionBloc, ConnectionState>(
              builder: (context, state) {
                // Only show sidebar if connected
                if (state.status == ConnectionStatus.connected) {
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
      ),
    );
  }
}