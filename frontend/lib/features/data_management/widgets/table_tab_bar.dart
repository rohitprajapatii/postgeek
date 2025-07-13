import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../models/table_tab.dart';
import 'schema_dropdown.dart';

class TableTabBar extends StatelessWidget {
  final List<TableTab> tabs;
  final String? activeTabId;
  final Function(String) onTabSelected;
  final Function(String) onTabClosed;
  final Function(int, int) onTabReorder;
  final Function(String schemaName, String tableName) onSchemaTableSelected;

  const TableTabBar({
    super.key,
    required this.tabs,
    required this.activeTabId,
    required this.onTabSelected,
    required this.onTabClosed,
    required this.onTabReorder,
    required this.onSchemaTableSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Row(
        children: [
          // Schema dropdown at the beginning
          SchemaDropdown(
            onTableSelected: onSchemaTableSelected,
          ),

          // Table tabs
          Expanded(
            child: tabs.isEmpty
                ? Container() // Empty container when no tabs
                : ReorderableListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: tabs.length,
                    onReorder: onTabReorder,
                    proxyDecorator: (child, index, animation) {
                      return AnimatedBuilder(
                        animation: animation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: 1.05,
                            child: child,
                          );
                        },
                        child: child,
                      );
                    },
                    itemBuilder: (context, index) {
                      final tab = tabs[index];
                      final isActive = tab.id == activeTabId;

                      return _TabItem(
                        key: ValueKey(tab.id),
                        tab: tab,
                        isActive: isActive,
                        onTap: () => onTabSelected(tab.id),
                        onClose: () => onTabClosed(tab.id),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _TabItem extends StatefulWidget {
  final TableTab tab;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onClose;

  const _TabItem({
    super.key,
    required this.tab,
    required this.isActive,
    required this.onTap,
    required this.onClose,
  });

  @override
  State<_TabItem> createState() => _TabItemState();
}

class _TabItemState extends State<_TabItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          height: 40,
          constraints: const BoxConstraints(
            minWidth: 120,
            maxWidth: 200,
          ),
          decoration: BoxDecoration(
            color: widget.isActive
                ? AppColors.background
                : _isHovered
                    ? AppColors.inputBackground.withOpacity(0.5)
                    : Colors.transparent,
            border: Border(
              bottom: BorderSide(
                color: widget.isActive ? AppColors.primary : Colors.transparent,
                width: 2,
              ),
              right: BorderSide(
                color: AppColors.border.withOpacity(0.5),
                width: 1,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                // Loading indicator or table icon
                if (widget.tab.isLoading)
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        widget.isActive
                            ? AppColors.primary
                            : AppColors.textTertiary,
                      ),
                    ),
                  )
                else
                  Icon(
                    Icons.table_view,
                    size: 14,
                    color: widget.isActive
                        ? AppColors.primary
                        : AppColors.textTertiary,
                  ),

                const SizedBox(width: 8),

                // Table name
                Expanded(
                  child: Text(
                    widget.tab.displayName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          widget.isActive ? FontWeight.w600 : FontWeight.w500,
                      color: widget.isActive
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Unsaved changes indicator
                if (widget.tab.hasUnsavedChanges)
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.warning,
                    ),
                  ),

                // Close button
                if (_isHovered || widget.tab.hasUnsavedChanges)
                  InkWell(
                    onTap: widget.onClose,
                    borderRadius: BorderRadius.circular(2),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      child: Icon(
                        Icons.close,
                        size: 12,
                        color: widget.isActive
                            ? AppColors.textSecondary
                            : AppColors.textTertiary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
