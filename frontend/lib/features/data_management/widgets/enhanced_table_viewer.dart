import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../models/table_tab.dart';
import '../models/table_details.dart';
import '../models/table_data.dart';

class EnhancedTableViewer extends StatelessWidget {
  final TableTab tab;
  final VoidCallback onRefresh;

  const EnhancedTableViewer({
    super.key,
    required this.tab,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (tab.isLoading) {
      return _buildLoadingState();
    }

    if (tab.errorMessage != null) {
      return _buildErrorState(tab.errorMessage!);
    }

    if (tab.tableDetails == null || tab.tableData == null) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        _buildHeader(context),
        Expanded(
          child: _buildDataTable(context),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Container(
      color: AppColors.background,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading ${tab.displayName}...',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Container(
      color: AppColors.background,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.error.withOpacity(0.3),
                ),
              ),
              child: Icon(
                Icons.error_outline,
                size: 32,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load ${tab.displayName}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRefresh,
              icon: Icon(Icons.refresh, size: 16),
              label: Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      color: AppColors.background,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.table_view_outlined,
              size: 32,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              'No data available',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final tableDetails = tab.tableDetails!;
    final tableData = tab.tableData!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(
            color: AppColors.border,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Table info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.table_view,
                        size: 16,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      tab.fullTableName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildInfoChip(
                      '${tableData.pagination.total} rows',
                      Icons.list_alt,
                      AppColors.info,
                    ),
                    const SizedBox(width: 8),
                    _buildInfoChip(
                      '${tableDetails.columns.length} columns',
                      Icons.view_column,
                      AppColors.accent,
                    ),
                    if (tableDetails.primaryKeys.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      _buildInfoChip(
                        '${tableDetails.primaryKeys.length} PK',
                        Icons.key,
                        AppColors.warning,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Actions
          Row(
            children: [
              IconButton(
                onPressed: onRefresh,
                icon: Icon(Icons.refresh, size: 18),
                tooltip: 'Refresh data',
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.inputBackground,
                  foregroundColor: AppColors.textSecondary,
                  padding: const EdgeInsets.all(8),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {
                  // TODO: Implement export functionality
                },
                icon: Icon(Icons.download, size: 18),
                tooltip: 'Export data',
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.inputBackground,
                  foregroundColor: AppColors.textSecondary,
                  padding: const EdgeInsets.all(8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable(BuildContext context) {
    final tableDetails = tab.tableDetails!;
    final tableData = tab.tableData!;

    if (tableData.data.isEmpty) {
      return Container(
        color: AppColors.background,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inbox_outlined,
                size: 32,
                color: AppColors.textTertiary,
              ),
              const SizedBox(height: 16),
              Text(
                'No data in this table',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      color: AppColors.background,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: DataTable(
            horizontalMargin: 16,
            columnSpacing: 24,
            headingRowColor: MaterialStateProperty.all(AppColors.surface),
            headingRowHeight: 48,
            dataRowHeight: 40,
            headingTextStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            dataTextStyle: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
            border: TableBorder.all(
              color: AppColors.border.withOpacity(0.5),
              width: 1,
            ),
            columns: tableDetails.columns.map((column) {
              return DataColumn(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (column.isPrimaryKey)
                      Icon(
                        Icons.key,
                        size: 12,
                        color: AppColors.warning,
                      ),
                    if (column.isForeignKey)
                      Icon(
                        Icons.link,
                        size: 12,
                        color: AppColors.info,
                      ),
                    if (column.isPrimaryKey || column.isForeignKey)
                      const SizedBox(width: 4),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            column.columnName,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            column.dataType,
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.textTertiary,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            rows: tableData.data.map((row) {
              return DataRow(
                cells: tableDetails.columns.map((column) {
                  final value = row[column.columnName];
                  return DataCell(
                    _buildCellContent(value, column),
                    onTap: () => _copyCellValue(context, value),
                  );
                }).toList(),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildCellContent(dynamic value, ColumnInfo column) {
    if (value == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.textTertiary.withOpacity(0.2),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          'NULL',
          style: TextStyle(
            fontSize: 10,
            fontStyle: FontStyle.italic,
            color: AppColors.textTertiary,
          ),
        ),
      );
    }

    String displayValue = value.toString();
    if (displayValue.length > 50) {
      displayValue = '${displayValue.substring(0, 50)}...';
    }

    Color? textColor;
    if (column.dataType.toLowerCase().contains('bool')) {
      textColor = value == true ? AppColors.success : AppColors.error;
    } else if (column.dataType.toLowerCase().contains('int') ||
        column.dataType.toLowerCase().contains('num') ||
        column.dataType.toLowerCase().contains('decimal')) {
      textColor = AppColors.info;
    }

    return Text(
      displayValue,
      style: TextStyle(
        color: textColor ?? AppColors.textSecondary,
        fontSize: 12,
      ),
      overflow: TextOverflow.ellipsis,
    );
  }

  void _copyCellValue(BuildContext context, dynamic value) {
    if (value != null) {
      Clipboard.setData(ClipboardData(text: value.toString()));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Copied to clipboard'),
          duration: Duration(seconds: 1),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }
}
