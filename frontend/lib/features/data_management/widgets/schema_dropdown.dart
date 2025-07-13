import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../bloc/data_management_bloc.dart';
import '../models/schema_info.dart';

class SchemaDropdown extends StatefulWidget {
  final Function(String schemaName, String tableName) onTableSelected;

  const SchemaDropdown({
    super.key,
    required this.onTableSelected,
  });

  @override
  State<SchemaDropdown> createState() => _SchemaDropdownState();
}

class _SchemaDropdownState extends State<SchemaDropdown> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isDropdownOpen = false;

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _toggleDropdown() {
    if (_isDropdownOpen) {
      _removeOverlay();
    } else {
      _showDropdown();
    }
  }

  void _showDropdown() {
    if (_isDropdownOpen) return;

    _isDropdownOpen = true;
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
    }
    _isDropdownOpen = false;
  }

  OverlayEntry _createOverlayEntry() {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    return OverlayEntry(
      builder: (context) => Positioned(
        width: 320,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, size.height + 4),
          child: Material(
            elevation: 8,
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              constraints: BoxConstraints(
                maxHeight: 400,
                minHeight: 200,
              ),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.border,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                    child: Row(
                      children: [
                        Icon(
                          Icons.folder_outlined,
                          color: AppColors.textSecondary,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Schema Explorer',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: _removeOverlay,
                          icon: Icon(
                            Icons.close,
                            size: 18,
                            color: AppColors.textSecondary,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(
                            minWidth: 24,
                            minHeight: 24,
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
                          return Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.primary,
                              ),
                            ),
                          );
                        }

                        if (state.schemas.isEmpty) {
                          return _buildEmptyState();
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: state.schemas.length,
                          itemBuilder: (context, index) {
                            final schema = state.schemas[index];
                            return _SchemaExpansionTile(
                              schema: schema,
                              onTableSelected: (tableName) {
                                widget.onTableSelected(
                                    schema.schemaName, tableName);
                                _removeOverlay();
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_off,
            size: 48,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: 16),
          Text(
            'No schemas found',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () {
              context.read<DataManagementBloc>().add(const LoadSchemas());
            },
            icon: Icon(Icons.refresh, size: 16),
            label: Text('Refresh'),
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size.zero,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: _toggleDropdown,
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: _isDropdownOpen
                ? AppColors.primary.withOpacity(0.1)
                : AppColors.surface,
            border: Border(
              right: BorderSide(
                color: AppColors.border.withOpacity(0.5),
                width: 1,
              ),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.folder_outlined,
                color: _isDropdownOpen
                    ? AppColors.primary
                    : AppColors.textSecondary,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'Schema Explorer',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _isDropdownOpen
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                _isDropdownOpen
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                color: _isDropdownOpen
                    ? AppColors.primary
                    : AppColors.textSecondary,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SchemaExpansionTile extends StatefulWidget {
  final SchemaInfo schema;
  final Function(String tableName) onTableSelected;

  const _SchemaExpansionTile({
    required this.schema,
    required this.onTableSelected,
  });

  @override
  State<_SchemaExpansionTile> createState() => _SchemaExpansionTileState();
}

class _SchemaExpansionTileState extends State<_SchemaExpansionTile> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: ExpansionTile(
        leading: Icon(
          _isExpanded ? Icons.folder_open : Icons.folder,
          color: AppColors.primary,
          size: 18,
        ),
        title: Text(
          widget.schema.schemaName,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          '${widget.schema.tables.length} tables',
          style: TextStyle(
            fontSize: 11,
            color: AppColors.textTertiary,
          ),
        ),
        trailing: Icon(
          _isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
          color: AppColors.textTertiary,
          size: 16,
        ),
        onExpansionChanged: (expanded) {
          setState(() => _isExpanded = expanded);
        },
        children: widget.schema.tables.map((table) {
          return _TableListTile(
            table: table,
            onTap: () => widget.onTableSelected(table.tableName),
          );
        }).toList(),
      ),
    );
  }
}

class _TableListTile extends StatefulWidget {
  final TableInfo table;
  final VoidCallback onTap;

  const _TableListTile({
    required this.table,
    required this.onTap,
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
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          margin: const EdgeInsets.only(left: 16, right: 8),
          decoration: BoxDecoration(
            color: _isHovered
                ? AppColors.primary.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              Icon(
                Icons.table_view,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.table.tableName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                '${widget.table.rowCount} rows',
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
