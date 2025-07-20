import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../bloc/queries_bloc.dart';

class ExtensionNotEnabledCard extends StatelessWidget {
  final String message;
  final String hint;

  const ExtensionNotEnabledCard({
    super.key,
    required this.message,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.warning.withOpacity(0.1),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.warning, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: AppColors.warning),
                const SizedBox(width: 12),
                Text(
                  'Feature Not Available',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(color: AppColors.warning),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              hint,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 16),
            BlocBuilder<QueriesBloc, QueriesState>(
              builder: (context, state) {
                if (state.status == QueriesStatus.enablingExtension) {
                  return const Center(child: CircularProgressIndicator());
                }
                return ElevatedButton.icon(
                  onPressed: () {
                    context.read<QueriesBloc>().add(EnableExtension());
                  },
                  icon: const Icon(Icons.rocket_launch),
                  label: const Text('Try to Enable Extension'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.warning,
                    foregroundColor: Colors.white,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
