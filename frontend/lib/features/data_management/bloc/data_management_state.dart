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
  final bool isSearching;
  final String? errorMessage;

  // Tab management
  final List<TableTab> openTabs;
  final String? activeTabId;

  // Legacy fields for backward compatibility
  final TableDetails? selectedTableDetails;
  final PaginatedTableData? tableData;
  final QueryResult? queryResult;
  final List<Map<String, dynamic>> foreignKeyData;

  // Reverse relation dialog state
  final bool isReverseRelationDialogOpen;
  final ReverseRelationData? reverseRelationData;
  final bool isLoadingReverseRelation;

  const DataManagementState({
    required this.status,
    this.schemas = const [],
    this.searchResults = const [],
    this.isSearching = false,
    this.errorMessage,
    this.openTabs = const [],
    this.activeTabId,
    this.selectedTableDetails,
    this.tableData,
    this.queryResult,
    this.foreignKeyData = const [],
    this.isReverseRelationDialogOpen = false,
    this.reverseRelationData,
    this.isLoadingReverseRelation = false,
  });

  const DataManagementState.initial()
      : status = DataManagementStatus.initial,
        schemas = const [],
        searchResults = const [],
        isSearching = false,
        errorMessage = null,
        openTabs = const [],
        activeTabId = null,
        selectedTableDetails = null,
        tableData = null,
        queryResult = null,
        foreignKeyData = const [],
        isReverseRelationDialogOpen = false,
        reverseRelationData = null,
        isLoadingReverseRelation = false;

  TableTab? get activeTab {
    if (activeTabId == null) return null;
    try {
      return openTabs.firstWhere((tab) => tab.id == activeTabId);
    } catch (e) {
      return null;
    }
  }

  bool get hasOpenTabs => openTabs.isNotEmpty;

  DataManagementState copyWith({
    DataManagementStatus? status,
    List<SchemaInfo>? schemas,
    List<TableInfo>? searchResults,
    bool? isSearching,
    String? errorMessage,
    List<TableTab>? openTabs,
    String? activeTabId,
    TableDetails? selectedTableDetails,
    PaginatedTableData? tableData,
    QueryResult? queryResult,
    List<Map<String, dynamic>>? foreignKeyData,
    bool? isReverseRelationDialogOpen,
    ReverseRelationData? reverseRelationData,
    bool? isLoadingReverseRelation,
  }) {
    return DataManagementState(
      status: status ?? this.status,
      schemas: schemas ?? this.schemas,
      searchResults: searchResults ?? this.searchResults,
      isSearching: isSearching ?? this.isSearching,
      errorMessage: errorMessage,
      openTabs: openTabs ?? this.openTabs,
      activeTabId: activeTabId ?? this.activeTabId,
      selectedTableDetails: selectedTableDetails ?? this.selectedTableDetails,
      tableData: tableData ?? this.tableData,
      queryResult: queryResult ?? this.queryResult,
      foreignKeyData: foreignKeyData ?? this.foreignKeyData,
      isReverseRelationDialogOpen:
          isReverseRelationDialogOpen ?? this.isReverseRelationDialogOpen,
      reverseRelationData: reverseRelationData ?? this.reverseRelationData,
      isLoadingReverseRelation:
          isLoadingReverseRelation ?? this.isLoadingReverseRelation,
    );
  }

  @override
  List<Object?> get props => [
        status,
        schemas,
        searchResults,
        isSearching,
        errorMessage,
        openTabs,
        activeTabId,
        selectedTableDetails,
        tableData,
        queryResult,
        foreignKeyData,
        isReverseRelationDialogOpen,
        reverseRelationData,
        isLoadingReverseRelation,
      ];
}
