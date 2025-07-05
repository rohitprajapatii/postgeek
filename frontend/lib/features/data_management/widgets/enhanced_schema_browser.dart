import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../bloc/data_management_bloc.dart';
import '../models/schema_info.dart';

class EnhancedSchemaBrowser extends StatelessWidget {
  const EnhancedSchemaBrowser({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: AppColors.border.withOpacity(0.5),
                width: 1,
              ),
            ),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.folder_outlined,
                color: AppColors.textSecondary,
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                'Schema Explorer',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),

        // Content
        Expanded(
          child: BlocBuilder<DataManagementBloc, DataManagementState>(
            builder: (context, state) {
              if (state.status == DataManagementStatus.loading &&
                  state.schemas.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                );
              }

              if (state.schemas.isEmpty) {
                return _buildEmptyState(context);
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: state.schemas.length,
                itemBuilder: (context, index) {
                  final schema = state.schemas[index];
                  return _SchemaExpansionTile(schema: schema);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.folder_off_outlined,
            size: 32,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: 16),
          const Text(
            'No schemas found',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Check your connection and try refreshing',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {
              context.read<DataManagementBloc>().add(const LoadSchemas());
            },
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Refresh'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              side: const BorderSide(color: AppColors.border),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }
}

class _SchemaExpansionTile extends StatefulWidget {
  final SchemaInfo schema;

  const _SchemaExpansionTile({required this.schema});

  @override
  State<_SchemaExpansionTile> createState() => _SchemaExpansionTileState();
}

class _SchemaExpansionTileState extends State<_SchemaExpansionTile> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: _isExpanded
            ? AppColors.inputBackground.withOpacity(0.3)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          expansionTileTheme: const ExpansionTileThemeData(
            backgroundColor: Colors.transparent,
            collapsedBackgroundColor: Colors.transparent,
            tilePadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            childrenPadding: EdgeInsets.only(left: 8, bottom: 4),
          ),
        ),
        child: ExpansionTile(
          leading: Icon(
            _isExpanded ? Icons.folder_open : Icons.folder,
            color: AppColors.primary,
            size: 18,
          ),
          title: Text(
            widget.schema.schemaName,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          subtitle: Text(
            '${widget.schema.tables.length} tables',
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textTertiary,
            ),
          ),
          trailing: Icon(
            _isExpanded
                ? Icons.keyboard_arrow_down
                : Icons.keyboard_arrow_right,
            color: AppColors.textTertiary,
            size: 16,
          ),
          onExpansionChanged: (expanded) {
            setState(() => _isExpanded = expanded);
          },
          children: widget.schema.tables.map((table) {
            return _TableListTile(
              schema: widget.schema.schemaName,
              table: table,
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _TableListTile extends StatefulWidget {
  final String schema;
  final TableInfo table;

  const _TableListTile({
    required this.schema,
    required this.table,
  });

  @override
  State<_TableListTile> createState() => _TableListTileState();
}

class _TableListTileState extends State<_TableListTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        decoration: BoxDecoration(
          color: _isHovered
              ? AppColors.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: ListTile(
          dense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          leading: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Icon(
              Icons.table_view,
              size: 14,
              color: AppColors.accent,
            ),
          ),
          title: Text(
            widget.table.tableName,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: _isHovered ? AppColors.primary : AppColors.textPrimary,
            ),
          ),
          subtitle: Text(
            '${widget.table.rowCount} rows',
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textTertiary,
            ),
          ),
          trailing: Icon(
            Icons.open_in_new,
            size: 12,
            color: _isHovered ? AppColors.primary : AppColors.textTertiary,
          ),
          onTap: () {
            context.read<DataManagementBloc>().add(
                  OpenTableTab(
                    schemaName: widget.schema,
                    tableName: widget.table.tableName,
                  ),
                );
          },
        ),
      ),
    );
  }
}
