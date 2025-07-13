import 'package:equatable/equatable.dart';
import 'table_details.dart';
import 'table_data.dart';

class TableTab extends Equatable {
  final String id;
  final String displayName;
  final String schemaName;
  final String tableName;
  final bool isLoading;
  final bool hasUnsavedChanges;
  final TableDetails? tableDetails;
  final PaginatedTableData? tableData;
  final String? errorMessage;
  final String searchFilter;
  final PaginatedTableData? filteredTableData;

  const TableTab({
    required this.id,
    required this.displayName,
    required this.schemaName,
    required this.tableName,
    this.isLoading = false,
    this.hasUnsavedChanges = false,
    this.tableDetails,
    this.tableData,
    this.errorMessage,
    this.searchFilter = '',
    this.filteredTableData,
  });

  String get fullTableName => '$schemaName.$tableName';

  TableTab copyWith({
    String? id,
    String? displayName,
    String? schemaName,
    String? tableName,
    bool? isLoading,
    bool? hasUnsavedChanges,
    TableDetails? tableDetails,
    PaginatedTableData? tableData,
    String? errorMessage,
    String? searchFilter,
    PaginatedTableData? filteredTableData,
    bool clearFilteredTableData = false,
  }) {
    return TableTab(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      schemaName: schemaName ?? this.schemaName,
      tableName: tableName ?? this.tableName,
      isLoading: isLoading ?? this.isLoading,
      hasUnsavedChanges: hasUnsavedChanges ?? this.hasUnsavedChanges,
      tableDetails: tableDetails ?? this.tableDetails,
      tableData: tableData ?? this.tableData,
      errorMessage: errorMessage ?? this.errorMessage,
      searchFilter: searchFilter ?? this.searchFilter,
      filteredTableData: clearFilteredTableData
          ? null
          : (filteredTableData ?? this.filteredTableData),
    );
  }

  @override
  List<Object?> get props => [
        id,
        displayName,
        schemaName,
        tableName,
        isLoading,
        hasUnsavedChanges,
        tableDetails,
        tableData,
        errorMessage,
        searchFilter,
        filteredTableData,
      ];
}
