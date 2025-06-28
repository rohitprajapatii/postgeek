part of 'data_management_bloc.dart';

enum DataManagementStatus {
  initial,
  loading,
  loaded,
  error,
}

class DataManagementState extends Equatable {
  final DataManagementStatus status;
  final List<SchemaInfo> schemas;
  final List<TableInfo> searchResults;
  final TableDetails? selectedTableDetails;
  final PaginatedTableData? tableData;
  final QueryResult? queryResult;
  final List<Map<String, dynamic>> foreignKeyData;
  final String? exportData;
  final String? errorMessage;
  final bool isSearching;
  final bool isExecutingQuery;
  final bool isExporting;

  const DataManagementState({
    this.status = DataManagementStatus.initial,
    this.schemas = const [],
    this.searchResults = const [],
    this.selectedTableDetails,
    this.tableData,
    this.queryResult,
    this.foreignKeyData = const [],
    this.exportData,
    this.errorMessage,
    this.isSearching = false,
    this.isExecutingQuery = false,
    this.isExporting = false,
  });

  DataManagementState copyWith({
    DataManagementStatus? status,
    List<SchemaInfo>? schemas,
    List<TableInfo>? searchResults,
    TableDetails? selectedTableDetails,
    PaginatedTableData? tableData,
    QueryResult? queryResult,
    List<Map<String, dynamic>>? foreignKeyData,
    String? exportData,
    String? errorMessage,
    bool? isSearching,
    bool? isExecutingQuery,
    bool? isExporting,
  }) {
    return DataManagementState(
      status: status ?? this.status,
      schemas: schemas ?? this.schemas,
      searchResults: searchResults ?? this.searchResults,
      selectedTableDetails: selectedTableDetails ?? this.selectedTableDetails,
      tableData: tableData ?? this.tableData,
      queryResult: queryResult ?? this.queryResult,
      foreignKeyData: foreignKeyData ?? this.foreignKeyData,
      exportData: exportData ?? this.exportData,
      errorMessage: errorMessage ?? this.errorMessage,
      isSearching: isSearching ?? this.isSearching,
      isExecutingQuery: isExecutingQuery ?? this.isExecutingQuery,
      isExporting: isExporting ?? this.isExporting,
    );
  }

  // Named constructors for common states
  const DataManagementState.initial()
      : this(status: DataManagementStatus.initial);

  const DataManagementState.loading()
      : this(status: DataManagementStatus.loading);

  const DataManagementState.loaded({
    List<SchemaInfo>? schemas,
    List<TableInfo>? searchResults,
    TableDetails? selectedTableDetails,
    PaginatedTableData? tableData,
    QueryResult? queryResult,
    List<Map<String, dynamic>>? foreignKeyData,
    String? exportData,
  }) : this(
          status: DataManagementStatus.loaded,
          schemas: schemas ?? const [],
          searchResults: searchResults ?? const [],
          selectedTableDetails: selectedTableDetails,
          tableData: tableData,
          queryResult: queryResult,
          foreignKeyData: foreignKeyData ?? const [],
          exportData: exportData,
        );

  const DataManagementState.error(String errorMessage)
      : this(
          status: DataManagementStatus.error,
          errorMessage: errorMessage,
        );

  @override
  List<Object?> get props => [
        status,
        schemas,
        searchResults,
        selectedTableDetails,
        tableData,
        queryResult,
        foreignKeyData,
        exportData,
        errorMessage,
        isSearching,
        isExecutingQuery,
        isExporting,
      ];
}
