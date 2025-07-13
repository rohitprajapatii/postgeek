import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../models/table_tab.dart';
import '../models/table_details.dart';
import '../models/table_data.dart';
import '../bloc/data_management_bloc.dart';

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
            dataRowHeight: 48,
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
            columns: [
              // Regular columns
              ...tableDetails.columns.map((column) {
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
              // Reverse Relations column - show if any row has reverse relations
              if (tableData.data.any((row) => row.reverseRelations.isNotEmpty))
                DataColumn(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.arrow_back,
                        size: 12,
                        color: AppColors.accent,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Reverse Relations',
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'referenced by',
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
                ),
            ],
            rows: tableData.data.map((row) {
              final hasReverseRelationsColumn =
                  tableData.data.any((r) => r.reverseRelations.isNotEmpty);

              return DataRow(
                cells: [
                  // Regular column cells
                  ...tableDetails.columns.map((column) {
                    final value = row.data[column.columnName];
                    return DataCell(
                      _buildCellContent(value, column, row),
                      onTap: () => _handleCellTap(context, value, column, row),
                    );
                  }).toList(),
                  // Reverse Relations cell (always include if column exists)
                  if (hasReverseRelationsColumn)
                    DataCell(
                      _buildReverseRelationsCell(context, row),
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildCellContent(
      dynamic value, ColumnInfo column, EnhancedTableRow row) {
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
    bool isClickable = false;

    // Check if this is a foreign key column with relation data
    if (column.isForeignKey && row.relations.containsKey(column.columnName)) {
      textColor = AppColors.info;
      isClickable = true;
    } else if (column.dataType.toLowerCase().contains('bool')) {
      textColor = value == true ? AppColors.success : AppColors.error;
    } else if (column.dataType.toLowerCase().contains('int') ||
        column.dataType.toLowerCase().contains('num') ||
        column.dataType.toLowerCase().contains('decimal')) {
      textColor = AppColors.info;
    }

    Widget content = Text(
      displayValue,
      style: TextStyle(
        color: textColor ?? AppColors.textSecondary,
        fontSize: 12,
        decoration: isClickable ? TextDecoration.underline : null,
      ),
      overflow: TextOverflow.ellipsis,
    );

    if (isClickable) {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.link,
            size: 12,
            color: AppColors.info,
          ),
          const SizedBox(width: 4),
          Flexible(child: content),
        ],
      );
    }

    return content;
  }

  void _handleCellTap(BuildContext context, dynamic value, ColumnInfo column,
      EnhancedTableRow row) {
    // If it's a foreign key column with relation data, open the relation tab
    if (column.isForeignKey && row.relations.containsKey(column.columnName)) {
      final relationData = row.relations[column.columnName]!;

      // Import the BLoC and its events
      final bloc = context.read<DataManagementBloc>();
      bloc.add(OpenRelationTab(
        sourceSchema: tab.schemaName,
        sourceTable: tab.tableName,
        sourceColumn: column.columnName,
        relationValue: value.toString(),
        targetSchema: relationData.referencedSchema,
        targetTable: relationData.referencedTable,
        targetColumn: relationData.referencedColumn,
      ));
    } else {
      // Default behavior - copy to clipboard
      _copyCellValue(context, value);
    }
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

  Widget _buildReverseRelationsCell(
      BuildContext context, EnhancedTableRow row) {
    if (row.reverseRelations.isEmpty) {
      return Text(
        '-',
        style: TextStyle(
          fontSize: 11,
          color: AppColors.textTertiary,
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: row.reverseRelations.entries.map((entry) {
          final reverseRelation = entry.value;

          // Safe string extraction for display
          String safeTableName;
          int safeRelationCount;
          try {
            safeTableName = reverseRelation.referencingTable.toString();
            safeRelationCount = reverseRelation.relationCount;
          } catch (e) {
            print(
                '[EnhancedTableViewer] ❌ Error extracting reverseRelation display values: $e');
            safeTableName = 'Unknown';
            safeRelationCount = 0;
          }

          return Padding(
            padding: const EdgeInsets.only(right: 4),
            child: InkWell(
              onTap: () =>
                  _handleReverseRelationTap(context, row, reverseRelation),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: AppColors.accent.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.arrow_back,
                      size: 10,
                      color: AppColors.accent,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '$safeTableName ($safeRelationCount)',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.accent,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _handleReverseRelationTap(
    BuildContext context,
    EnhancedTableRow row,
    ReverseRelationInfo reverseRelation,
  ) {
    print(
        '[EnhancedTableViewer] Reverse relation tapped: ${reverseRelation.referencingTable}');

    // DEBUG: Check the actual types of reverseRelation properties
    print('[EnhancedTableViewer] DEBUG - reverseRelation properties:');
    print(
        '  referencingTable: ${reverseRelation.referencingTable} (${reverseRelation.referencingTable.runtimeType})');
    print(
        '  referencingSchema: ${reverseRelation.referencingSchema} (${reverseRelation.referencingSchema.runtimeType})');
    print(
        '  referencingColumn: ${reverseRelation.referencingColumn} (${reverseRelation.referencingColumn.runtimeType})');

    // Find the primary key value for this row
    final primaryKeyColumns = tab.tableDetails!.primaryKeys;
    if (primaryKeyColumns.isEmpty) {
      print('[EnhancedTableViewer] ❌ No primary key columns found');
      return;
    }

    final primaryKeyValue = row.data[primaryKeyColumns.first];
    if (primaryKeyValue == null) {
      print('[EnhancedTableViewer] ❌ Primary key value is null');
      return;
    }

    print(
        '[EnhancedTableViewer] Primary key: ${primaryKeyColumns.first} = $primaryKeyValue');

    // Create a safe version of the reverseRelation with guaranteed string values
    final safeReverseRelation = ReverseRelationInfo(
      referencingTable: reverseRelation.referencingTable.toString(),
      referencingSchema: reverseRelation.referencingSchema.toString(),
      referencingColumn: reverseRelation.referencingColumn.toString(),
      relationCount: reverseRelation.relationCount,
    );

    print(
        '[EnhancedTableViewer] Created safe reverseRelation with string values');

    // Show the reverse relation dialog directly
    _showReverseRelationDialog(context, safeReverseRelation,
        primaryKeyColumns.first, primaryKeyValue.toString());
  }

  void _showReverseRelationDialog(
    BuildContext context,
    ReverseRelationInfo reverseRelation,
    String referencedColumn,
    String recordId,
  ) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return BlocProvider.value(
          value: context.read<DataManagementBloc>(),
          child: ReverseRelationDialogContent(
            reverseRelation: reverseRelation,
            sourceSchema: tab.schemaName,
            sourceTable: tab.tableName,
            referencedColumn: referencedColumn,
            recordId: recordId,
          ),
        );
      },
    );
  }
}

class ReverseRelationDialogContent extends StatefulWidget {
  final ReverseRelationInfo reverseRelation;
  final String sourceSchema;
  final String sourceTable;
  final String referencedColumn;
  final String recordId;

  const ReverseRelationDialogContent({
    super.key,
    required this.reverseRelation,
    required this.sourceSchema,
    required this.sourceTable,
    required this.referencedColumn,
    required this.recordId,
  });

  @override
  State<ReverseRelationDialogContent> createState() =>
      _ReverseRelationDialogContentState();
}

class _ReverseRelationDialogContentState
    extends State<ReverseRelationDialogContent> {
  ReverseRelationData? reverseRelationData;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      print('[ReverseRelationDialogContent] Loading data...');

      // Step 1: Check basic widget properties first
      try {
        print('[ReverseRelationDialogContent] Widget properties:');
        print(
            '  sourceSchema: ${widget.sourceSchema} (${widget.sourceSchema.runtimeType})');
        print(
            '  sourceTable: ${widget.sourceTable} (${widget.sourceTable.runtimeType})');
        print(
            '  referencedColumn: ${widget.referencedColumn} (${widget.referencedColumn.runtimeType})');
        print(
            '  recordId: ${widget.recordId} (${widget.recordId.runtimeType})');
      } catch (e) {
        print(
            '[ReverseRelationDialogContent] ❌ Error accessing widget properties: $e');
        throw Exception('Error accessing widget properties: $e');
      }

      // Step 2: Check reverse relation properties
      try {
        print('[ReverseRelationDialogContent] Reverse relation properties:');
        print('  reverseRelation type: ${widget.reverseRelation.runtimeType}');
        print(
            '  referencingSchema: ${widget.reverseRelation.referencingSchema} (${widget.reverseRelation.referencingSchema.runtimeType})');
        print(
            '  referencingTable: ${widget.reverseRelation.referencingTable} (${widget.reverseRelation.referencingTable.runtimeType})');
        print(
            '  referencingColumn: ${widget.reverseRelation.referencingColumn} (${widget.reverseRelation.referencingColumn.runtimeType})');
      } catch (e) {
        print(
            '[ReverseRelationDialogContent] ❌ Error accessing reverse relation properties: $e');
        throw Exception('Error accessing reverse relation properties: $e');
      }

      // Step 3: Get API service
      final apiService = context.read<DataManagementBloc>().apiService;

      // Step 4: Build API URL safely
      String apiUrl;
      try {
        final sourceSchema = widget.sourceSchema.toString();
        final sourceTable = widget.sourceTable.toString();
        final referencedColumn = widget.referencedColumn.toString();
        final recordId = widget.recordId.toString();

        apiUrl =
            '/api/data-management/tables/$sourceSchema/$sourceTable/reverse-relations/$referencedColumn/$recordId';
        print('[ReverseRelationDialogContent] API URL: $apiUrl');
      } catch (e) {
        print('[ReverseRelationDialogContent] ❌ Error building API URL: $e');
        throw Exception('Error building API URL: $e');
      }

      // Step 5: Defensively extract string values with enhanced safety
      String safeStringExtract(dynamic value, String fieldName) {
        try {
          if (value == null) {
            print(
                '[ReverseRelationDialogContent] ⚠️ $fieldName is null, using empty string');
            return '';
          }

          if (value is String) {
            return value;
          } else if (value is List) {
            if (value.isNotEmpty) {
              final firstValue = value.first;
              print(
                  '[ReverseRelationDialogContent] ⚠️ Converting list to string for $fieldName: $value -> $firstValue');
              return firstValue?.toString() ?? '';
            } else {
              print(
                  '[ReverseRelationDialogContent] ⚠️ Empty list for $fieldName, using empty string');
              return '';
            }
          } else if (value is Map) {
            print(
                '[ReverseRelationDialogContent] ⚠️ Map detected for $fieldName, converting to string: $value');
            return value.toString();
          } else {
            print(
                '[ReverseRelationDialogContent] ⚠️ Converting $fieldName from ${value.runtimeType} to string: $value');
            return value.toString();
          }
        } catch (e) {
          print(
              '[ReverseRelationDialogContent] ❌ Error extracting $fieldName: $e, using empty string');
          return '';
        }
      }

      // Step 6: Create query parameters with extra safety
      final queryParams = <String, dynamic>{};

      try {
        // Try to access reverseRelation properties safely
        dynamic referencingSchema;
        dynamic referencingTable;
        dynamic referencingColumn;

        try {
          referencingSchema = widget.reverseRelation.referencingSchema;
        } catch (e) {
          print(
              '[ReverseRelationDialogContent] ❌ Error accessing referencingSchema: $e');
          referencingSchema = 'unknown';
        }

        try {
          referencingTable = widget.reverseRelation.referencingTable;
        } catch (e) {
          print(
              '[ReverseRelationDialogContent] ❌ Error accessing referencingTable: $e');
          referencingTable = 'unknown';
        }

        try {
          referencingColumn = widget.reverseRelation.referencingColumn;
        } catch (e) {
          print(
              '[ReverseRelationDialogContent] ❌ Error accessing referencingColumn: $e');
          referencingColumn = 'unknown';
        }

        queryParams['referencingSchema'] =
            safeStringExtract(referencingSchema, 'referencingSchema');
        queryParams['referencingTable'] =
            safeStringExtract(referencingTable, 'referencingTable');
        queryParams['referencingColumn'] =
            safeStringExtract(referencingColumn, 'referencingColumn');
        queryParams['limit'] = 50;
      } catch (e) {
        print(
            '[ReverseRelationDialogContent] ❌ Error building query parameters: $e');
        throw Exception('Error building query parameters: $e');
      }

      print('[ReverseRelationDialogContent] Final query params: $queryParams');

      // Step 7: Make API call with safe parameters
      print(
          '[ReverseRelationDialogContent] Making API call with safe parameters...');
      print('[ReverseRelationDialogContent] Parameter types:');
      queryParams.forEach((key, value) {
        print('  $key: $value (${value.runtimeType})');
      });

      // Debug: Try to serialize parameters manually to see if there's an issue
      try {
        final serializedParams =
            queryParams.map((key, value) => MapEntry(key, value.toString()));
        print(
            '[ReverseRelationDialogContent] Serialized params: $serializedParams');
      } catch (e) {
        print('[ReverseRelationDialogContent] ❌ Error serializing params: $e');
      }

      // Try alternative approach: build URL with query string manually
      try {
        final queryString = queryParams.entries
            .map((e) =>
                '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value.toString())}')
            .join('&');
        final fullUrl = '$apiUrl?$queryString';
        print('[ReverseRelationDialogContent] Alternative full URL: $fullUrl');

        // Try the manual URL approach first
        print(
            '[ReverseRelationDialogContent] Attempting API call with manual URL...');
        final response = await apiService.get(fullUrl);

        print(
            '[ReverseRelationDialogContent] ✅ Manual URL approach succeeded!');
        print(
            '[ReverseRelationDialogContent] Response status: ${response.statusCode}');
        print('[ReverseRelationDialogContent] Response data: ${response.data}');

        // Continue with the rest of the response handling...
        if (response.statusCode == 200) {
          // [Rest of the response handling code remains the same]
          final responseData = response.data;
          print(
              '[ReverseRelationDialogContent] Raw response data: $responseData');
          print(
              '[ReverseRelationDialogContent] Data type: ${responseData.runtimeType}');

          // Handle different response structures
          List<Map<String, dynamic>> records = [];
          int totalCount = 0;

          if (responseData is Map<String, dynamic>) {
            // If data is wrapped in a response object
            if (responseData.containsKey('data')) {
              final recordsData = responseData['data'];
              if (recordsData is List) {
                records = recordsData.map((record) {
                  if (record is Map<String, dynamic>) {
                    return record;
                  } else if (record is Map) {
                    return Map<String, dynamic>.from(record);
                  } else {
                    return <String, dynamic>{'value': record.toString()};
                  }
                }).toList();
              }
            }

            if (responseData.containsKey('totalCount')) {
              totalCount = (responseData['totalCount'] as num?)?.toInt() ?? 0;
            } else {
              totalCount = records.length;
            }
          } else if (responseData is List) {
            // If data is directly a list of records
            records = responseData.map((record) {
              if (record is Map<String, dynamic>) {
                return record;
              } else if (record is Map) {
                return Map<String, dynamic>.from(record);
              } else {
                return <String, dynamic>{'value': record.toString()};
              }
            }).toList();
            totalCount = records.length;
          }

          print(
              '[ReverseRelationDialogContent] Parsed ${records.length} records');

          setState(() {
            reverseRelationData = ReverseRelationData(
              referencingTable: queryParams['referencingTable'].toString(),
              referencingSchema: queryParams['referencingSchema'].toString(),
              referencingColumn: queryParams['referencingColumn'].toString(),
              relatedRecords: records,
              totalCount: totalCount,
            );
            isLoading = false;
          });
        } else {
          setState(() {
            errorMessage =
                'Failed to load data (Status: ${response.statusCode})';
            isLoading = false;
          });
        }
      } catch (e) {
        print(
            '[ReverseRelationDialogContent] ❌ Manual URL approach failed: $e');

        // Fallback: Try the original approach with queryParameters
        try {
          print(
              '[ReverseRelationDialogContent] Trying original queryParameters approach...');
          final response =
              await apiService.get(apiUrl, queryParameters: queryParams);

          print(
              '[ReverseRelationDialogContent] ✅ Original approach succeeded!');
          print(
              '[ReverseRelationDialogContent] Response status: ${response.statusCode}');
          print(
              '[ReverseRelationDialogContent] Response data: ${response.data}');

          if (response.statusCode == 200) {
            final responseData = response.data;
            print(
                '[ReverseRelationDialogContent] Raw response data: $responseData');
            print(
                '[ReverseRelationDialogContent] Data type: ${responseData.runtimeType}');

            // Handle different response structures
            List<Map<String, dynamic>> records = [];
            int totalCount = 0;

            if (responseData is Map<String, dynamic>) {
              // If data is wrapped in a response object
              if (responseData.containsKey('data')) {
                final recordsData = responseData['data'];
                if (recordsData is List) {
                  records = recordsData.map((record) {
                    if (record is Map<String, dynamic>) {
                      return record;
                    } else if (record is Map) {
                      return Map<String, dynamic>.from(record);
                    } else {
                      return <String, dynamic>{'value': record.toString()};
                    }
                  }).toList();
                }
              }

              if (responseData.containsKey('totalCount')) {
                totalCount = (responseData['totalCount'] as num?)?.toInt() ?? 0;
              } else {
                totalCount = records.length;
              }
            } else if (responseData is List) {
              // If data is directly a list of records
              records = responseData.map((record) {
                if (record is Map<String, dynamic>) {
                  return record;
                } else if (record is Map) {
                  return Map<String, dynamic>.from(record);
                } else {
                  return <String, dynamic>{'value': record.toString()};
                }
              }).toList();
              totalCount = records.length;
            }

            print(
                '[ReverseRelationDialogContent] Parsed ${records.length} records');

            setState(() {
              reverseRelationData = ReverseRelationData(
                referencingTable: queryParams['referencingTable'].toString(),
                referencingSchema: queryParams['referencingSchema'].toString(),
                referencingColumn: queryParams['referencingColumn'].toString(),
                relatedRecords: records,
                totalCount: totalCount,
              );
              isLoading = false;
            });
          } else {
            setState(() {
              errorMessage =
                  'Failed to load data (Status: ${response.statusCode})';
              isLoading = false;
            });
          }
        } catch (e2) {
          print(
              '[ReverseRelationDialogContent] ❌ Both approaches failed. Original error: $e, Fallback error: $e2');
          setState(() {
            errorMessage = 'API call failed: $e2';
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print('[ReverseRelationDialogContent] Error: $e');
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            Expanded(
              child: _buildContent(),
            ),
            const SizedBox(height: 16),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.arrow_back,
                size: 20,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reverse Relations',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Records from ${widget.reverseRelation.referencingSchema}.${widget.reverseRelation.referencingTable}',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: Icon(
                Icons.close,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        if (reverseRelationData != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.info.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: AppColors.info,
                ),
                const SizedBox(width: 8),
                Text(
                  'Found ${reverseRelationData!.totalCount} records referencing this record',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.info,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(8),
        ),
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
                'Loading related records...',
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

    if (errorMessage != null) {
      return Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: AppColors.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Error loading data',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                errorMessage!,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadData,
                child: Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (reverseRelationData == null ||
        reverseRelationData!.relatedRecords.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inbox_outlined,
                size: 48,
                color: AppColors.textTertiary,
              ),
              const SizedBox(height: 16),
              Text(
                'No related records found',
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

    return _buildDataTable();
  }

  Widget _buildDataTable() {
    final records = reverseRelationData!.relatedRecords;

    // Get all unique column names from the records
    final columnNames = <String>{};
    for (final record in records) {
      columnNames.addAll(record.keys);
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            horizontalMargin: 16,
            columnSpacing: 24,
            headingRowColor: MaterialStateProperty.all(AppColors.surface),
            headingRowHeight: 40,
            dataRowHeight: 36,
            headingTextStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            dataTextStyle: TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
            border: TableBorder.all(
              color: AppColors.border.withOpacity(0.5),
              width: 1,
            ),
            columns: columnNames.map((columnName) {
              return DataColumn(
                label: Text(
                  columnName,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            rows: records.map((record) {
              return DataRow(
                cells: columnNames.map((columnName) {
                  final value = record[columnName];
                  return DataCell(
                    _buildCellContent(value),
                  );
                }).toList(),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildCellContent(dynamic value) {
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

    String displayValue;

    // Safe string conversion
    try {
      if (value is String) {
        displayValue = value;
      } else if (value is num) {
        displayValue = value.toString();
      } else if (value is bool) {
        displayValue = value.toString();
      } else if (value is List) {
        displayValue = '[${value.length} items]';
      } else if (value is Map) {
        displayValue = '{${value.length} fields}';
      } else {
        displayValue = value.toString();
      }
    } catch (e) {
      displayValue = '<error displaying value>';
    }

    if (displayValue.length > 50) {
      displayValue = '${displayValue.substring(0, 50)}...';
    }

    return Text(
      displayValue,
      style: TextStyle(
        color: AppColors.textSecondary,
        fontSize: 11,
      ),
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
