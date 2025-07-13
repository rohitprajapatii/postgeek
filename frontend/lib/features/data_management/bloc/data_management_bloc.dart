import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../core/services/api_service.dart';
import '../../connection/bloc/connection_bloc.dart';
import '../models/schema_info.dart';
import '../models/table_details.dart';
import '../models/table_data.dart';
import '../models/table_tab.dart';

part 'data_management_event.dart';
part 'data_management_state.dart';

class DataManagementBloc
    extends Bloc<DataManagementEvent, DataManagementState> {
  final ApiService apiService;
  final ConnectionBloc connectionBloc;

  DataManagementBloc({
    required this.apiService,
    required this.connectionBloc,
  }) : super(const DataManagementState.initial()) {
    on<LoadSchemas>(_onLoadSchemas);
    on<SearchTables>(_onSearchTables);
    on<LoadTableDetails>(_onLoadTableDetails);
    on<LoadTableData>(_onLoadTableData);
    on<OpenTableTab>(_onOpenTableTab);
    on<CloseTableTab>(_onCloseTableTab);
    on<SwitchToTab>(_onSwitchToTab);
    on<ReorderTabs>(_onReorderTabs);
    on<RefreshTabData>(_onRefreshTabData);
    on<CreateRecord>(_onCreateRecord);
    on<UpdateRecord>(_onUpdateRecord);
    on<DeleteRecord>(_onDeleteRecord);
    on<BulkInsertRecords>(_onBulkInsertRecords);
    on<ExecuteQuery>(_onExecuteQuery);
    on<ExportTableData>(_onExportTableData);
    on<LoadForeignKeyData>(_onLoadForeignKeyData);
    on<OpenRelationTab>(_onOpenRelationTab);
    on<LoadRelationData>(_onLoadRelationData);
    on<OpenReverseRelationDialog>(_onOpenReverseRelationDialog);
    on<CloseReverseRelationDialog>(_onCloseReverseRelationDialog);
    on<ResetDataManagement>(_onResetDataManagement);
  }

  Future<void> _onLoadSchemas(
    LoadSchemas event,
    Emitter<DataManagementState> emit,
  ) async {
    try {
      emit(state.copyWith(status: DataManagementStatus.loading));

      // print('[DataManagementBloc] Loading schemas...');

      final response = await apiService.get('/api/data-management/schemas');

      if (response.statusCode == 200) {
        final data = response.data;
        final List<SchemaInfo> schemas = (data['data'] as List)
            .map((schema) => SchemaInfo.fromJson(schema))
            .toList();

        // print('[DataManagementBloc] ✅ Loaded ${schemas.length} schemas');

        emit(state.copyWith(
          status: DataManagementStatus.loaded,
          schemas: schemas,
          errorMessage: null,
        ));
      } else {
        final errorMessage = response.statusCode == 400
            ? 'Database not connected. Please establish a connection first.'
            : 'Failed to load schemas';

        // print(
        //     '[DataManagementBloc] ❌ Error loading schemas: Status ${response.statusCode}');

        emit(state.copyWith(
          status: DataManagementStatus.error,
          errorMessage: errorMessage,
        ));
      }
    } catch (e) {
      // print('[DataManagementBloc] ❌ Error loading schemas: $e');

      // Check if it's a connection error
      String errorMessage = e.toString();
      if (errorMessage.contains('Error 400') ||
          errorMessage.toLowerCase().contains('not connected')) {
        errorMessage =
            'Database not connected. Please establish a connection first.';
      } else if (errorMessage.contains('Error 500')) {
        errorMessage = 'Server error occurred. Please try again later.';
      }

      emit(state.copyWith(
        status: DataManagementStatus.error,
        errorMessage: errorMessage,
      ));
    }
  }

  Future<void> _onSearchTables(
    SearchTables event,
    Emitter<DataManagementState> emit,
  ) async {
    if (event.searchTerm.isEmpty) {
      emit(state.copyWith(
        searchResults: [],
        isSearching: false,
      ));
      return;
    }

    try {
      emit(state.copyWith(isSearching: true));

      final response = await apiService.get(
        '/api/data-management/search/tables',
        queryParameters: {'q': event.searchTerm},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final List<TableInfo> searchResults = (data['data'] as List)
            .map((result) => TableInfo(
                  tableName: result['tableName'],
                  rowCount: result['rowCount'],
                ))
            .toList();

        emit(state.copyWith(
          searchResults: searchResults,
          isSearching: false,
        ));
      } else {
        emit(state.copyWith(
          isSearching: false,
          errorMessage: 'Search failed',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        isSearching: false,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onLoadTableDetails(
    LoadTableDetails event,
    Emitter<DataManagementState> emit,
  ) async {
    try {
      emit(state.copyWith(status: DataManagementStatus.loading));

      final response = await apiService.get(
        '/api/data-management/tables/${event.schemaName}/${event.tableName}/info',
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final tableDetails = TableDetails.fromJson(data['data']);

        emit(state.copyWith(
          status: DataManagementStatus.loaded,
          selectedTableDetails: tableDetails,
          errorMessage: null,
        ));
      } else {
        emit(state.copyWith(
          status: DataManagementStatus.error,
          errorMessage: 'Failed to load table details',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: DataManagementStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onLoadTableData(
    LoadTableData event,
    Emitter<DataManagementState> emit,
  ) async {
    try {
      emit(state.copyWith(status: DataManagementStatus.loading));

      final queryParams = event.queryOptions?.toQueryParameters() ?? {};

      final response = await apiService.get(
        '/api/data-management/tables/${event.schemaName}/${event.tableName}/data',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final tableData = PaginatedTableData.fromJson(data);

        emit(state.copyWith(
          status: DataManagementStatus.loaded,
          tableData: tableData,
          errorMessage: null,
        ));
      } else {
        emit(state.copyWith(
          status: DataManagementStatus.error,
          errorMessage: 'Failed to load table data',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: DataManagementStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  // Tab Management Event Handlers
  Future<void> _onOpenTableTab(
    OpenTableTab event,
    Emitter<DataManagementState> emit,
  ) async {
    final tabId = '${event.schemaName}.${event.tableName}';

    // Check if tab is already open
    final existingTabIndex =
        state.openTabs.indexWhere((tab) => tab.id == tabId);

    if (existingTabIndex != -1) {
      // Tab already exists, just switch to it
      emit(state.copyWith(activeTabId: tabId));
      return;
    }

    // Create new tab
    final newTab = TableTab(
      id: tabId,
      displayName: event.tableName,
      schemaName: event.schemaName,
      tableName: event.tableName,
      isLoading: true,
    );

    final updatedTabs = List<TableTab>.from(state.openTabs)..add(newTab);

    emit(state.copyWith(
      openTabs: updatedTabs,
      activeTabId: tabId,
    ));

    // Load table details and data
    try {
      final detailsResponse = await apiService.get(
        '/api/data-management/tables/${event.schemaName}/${event.tableName}/info',
      );

      if (detailsResponse.statusCode == 200) {
        final tableDetails =
            TableDetails.fromJson(detailsResponse.data['data']);

        final dataResponse = await apiService.get(
          '/api/data-management/tables/${event.schemaName}/${event.tableName}/data',
        );

        if (dataResponse.statusCode == 200) {
          final tableData = PaginatedTableData.fromJson(dataResponse.data);

          final updatedTab = newTab.copyWith(
            isLoading: false,
            tableDetails: tableDetails,
            tableData: tableData,
          );

          final finalTabs = state.openTabs
              .map((tab) => tab.id == tabId ? updatedTab : tab)
              .toList();

          emit(state.copyWith(openTabs: finalTabs));
        }
      }
    } catch (e) {
      final errorTab = newTab.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );

      final errorTabs = state.openTabs
          .map((tab) => tab.id == tabId ? errorTab : tab)
          .toList();

      emit(state.copyWith(openTabs: errorTabs));
    }
  }

  void _onCloseTableTab(
    CloseTableTab event,
    Emitter<DataManagementState> emit,
  ) {
    final updatedTabs =
        state.openTabs.where((tab) => tab.id != event.tabId).toList();

    String? newActiveTabId = state.activeTabId;
    if (state.activeTabId == event.tabId) {
      // If closing the active tab, switch to the last remaining tab
      newActiveTabId = updatedTabs.isNotEmpty ? updatedTabs.last.id : null;
    }

    emit(state.copyWith(
      openTabs: updatedTabs,
      activeTabId: newActiveTabId,
    ));
  }

  void _onSwitchToTab(
    SwitchToTab event,
    Emitter<DataManagementState> emit,
  ) {
    if (state.openTabs.any((tab) => tab.id == event.tabId)) {
      emit(state.copyWith(activeTabId: event.tabId));
    }
  }

  void _onReorderTabs(
    ReorderTabs event,
    Emitter<DataManagementState> emit,
  ) {
    final updatedTabs = List<TableTab>.from(state.openTabs);

    // Bounds checking to prevent index out of range errors
    if (event.oldIndex < 0 || event.oldIndex >= updatedTabs.length) {
      return;
    }

    int newIndex = event.newIndex;
    if (newIndex > updatedTabs.length) {
      newIndex = updatedTabs.length;
    }
    if (newIndex < 0) {
      newIndex = 0;
    }

    // If trying to move to the same position, do nothing
    if (event.oldIndex == newIndex) {
      return;
    }

    final item = updatedTabs.removeAt(event.oldIndex);

    // Adjust new index if it's beyond the current length after removal
    if (newIndex > updatedTabs.length) {
      newIndex = updatedTabs.length;
    }

    updatedTabs.insert(newIndex, item);

    emit(state.copyWith(openTabs: updatedTabs));
  }

  Future<void> _onRefreshTabData(
    RefreshTabData event,
    Emitter<DataManagementState> emit,
  ) async {
    final tab = state.openTabs.firstWhere((tab) => tab.id == event.tabId);

    final updatedTab = tab.copyWith(isLoading: true);
    final updatedTabs = state.openTabs
        .map((t) => t.id == event.tabId ? updatedTab : t)
        .toList();

    emit(state.copyWith(openTabs: updatedTabs));

    try {
      final response = await apiService.get(
        '/api/data-management/tables/${tab.schemaName}/${tab.tableName}/data',
      );

      if (response.statusCode == 200) {
        final tableData = PaginatedTableData.fromJson(response.data);

        final refreshedTab = tab.copyWith(
          isLoading: false,
          tableData: tableData,
          errorMessage: null,
        );

        final finalTabs = state.openTabs
            .map((t) => t.id == event.tabId ? refreshedTab : t)
            .toList();

        emit(state.copyWith(openTabs: finalTabs));
      }
    } catch (e) {
      final errorTab = tab.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );

      final errorTabs = state.openTabs
          .map((t) => t.id == event.tabId ? errorTab : t)
          .toList();

      emit(state.copyWith(openTabs: errorTabs));
    }
  }

  Future<void> _onCreateRecord(
    CreateRecord event,
    Emitter<DataManagementState> emit,
  ) async {
    try {
      final response = await apiService.post(
        '/api/data-management/tables/${event.schemaName}/${event.tableName}/records',
        data: {'data': event.record},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Reload table data to show the new record
        add(LoadTableData(
          schemaName: event.schemaName,
          tableName: event.tableName,
        ));
      } else {
        emit(state.copyWith(
          status: DataManagementStatus.error,
          errorMessage: 'Failed to create record',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: DataManagementStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onUpdateRecord(
    UpdateRecord event,
    Emitter<DataManagementState> emit,
  ) async {
    try {
      final response = await apiService.put(
        '/api/data-management/tables/${event.schemaName}/${event.tableName}/records',
        data: {
          'data': event.record,
          'where': event.primaryKey,
        },
      );

      if (response.statusCode == 200) {
        // Reload table data to show the updated record
        add(LoadTableData(
          schemaName: event.schemaName,
          tableName: event.tableName,
        ));
      } else {
        emit(state.copyWith(
          status: DataManagementStatus.error,
          errorMessage: 'Failed to update record',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: DataManagementStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onDeleteRecord(
    DeleteRecord event,
    Emitter<DataManagementState> emit,
  ) async {
    try {
      final response = await apiService.delete(
        '/api/data-management/tables/${event.schemaName}/${event.tableName}/records',
        data: {'where': event.primaryKey},
      );

      if (response.statusCode == 200) {
        // Reload table data to reflect the deletion
        add(LoadTableData(
          schemaName: event.schemaName,
          tableName: event.tableName,
        ));
      } else {
        emit(state.copyWith(
          status: DataManagementStatus.error,
          errorMessage: 'Failed to delete record',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: DataManagementStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onBulkInsertRecords(
    BulkInsertRecords event,
    Emitter<DataManagementState> emit,
  ) async {
    try {
      final response = await apiService.post(
        '/api/data-management/tables/${event.schemaName}/${event.tableName}/bulk-insert',
        data: {
          'records': event.records,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Reload table data to show the new records
        add(LoadTableData(
          schemaName: event.schemaName,
          tableName: event.tableName,
        ));
      } else {
        emit(state.copyWith(
          status: DataManagementStatus.error,
          errorMessage: 'Failed to bulk insert records',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: DataManagementStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onExecuteQuery(
    ExecuteQuery event,
    Emitter<DataManagementState> emit,
  ) async {
    try {
      emit(state.copyWith(status: DataManagementStatus.loading));

      final response = await apiService.post(
        '/api/data-management/query',
        data: {
          'query': event.query,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final queryResult = QueryResult.fromJson(data);

        emit(state.copyWith(
          status: DataManagementStatus.loaded,
          queryResult: queryResult,
          errorMessage: null,
        ));
      } else {
        emit(state.copyWith(
          status: DataManagementStatus.error,
          errorMessage: 'Failed to execute query',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: DataManagementStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onExportTableData(
    ExportTableData event,
    Emitter<DataManagementState> emit,
  ) async {
    try {
      final response = await apiService.get(
        '/api/data-management/tables/${event.schemaName}/${event.tableName}/export',
        queryParameters: {'format': event.format},
      );

      if (response.statusCode == 200) {
        // Handle export success (maybe show a success message)
        emit(state.copyWith(
          status: DataManagementStatus.loaded,
          errorMessage: null,
        ));
      } else {
        emit(state.copyWith(
          status: DataManagementStatus.error,
          errorMessage: 'Failed to export table data',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: DataManagementStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onLoadForeignKeyData(
    LoadForeignKeyData event,
    Emitter<DataManagementState> emit,
  ) async {
    try {
      final response = await apiService.get(
        '/api/data-management/tables/${event.schemaName}/${event.tableName}/foreign-keys/${event.columnName}',
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final List<Map<String, dynamic>> foreignKeyData =
            List<Map<String, dynamic>>.from(data['data'] as List);

        emit(state.copyWith(
          foreignKeyData: foreignKeyData,
          errorMessage: null,
        ));
      } else {
        emit(state.copyWith(
          errorMessage: 'Failed to load foreign key data',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        errorMessage: e.toString(),
      ));
    }
  }

  // Relation Navigation Event Handlers
  Future<void> _onOpenRelationTab(
    OpenRelationTab event,
    Emitter<DataManagementState> emit,
  ) async {
    final tabId =
        '${event.targetSchema}.${event.targetTable}@${event.relationValue}';

    // Check if tab is already open
    final existingTabIndex =
        state.openTabs.indexWhere((tab) => tab.id == tabId);

    if (existingTabIndex != -1) {
      // Tab already exists, just switch to it
      emit(state.copyWith(activeTabId: tabId));
      return;
    }

    // Create new tab for relation
    final newTab = TableTab(
      id: tabId,
      displayName: '${event.targetTable} (${event.relationValue})',
      schemaName: event.targetSchema,
      tableName: event.targetTable,
      isLoading: true,
    );

    final updatedTabs = List<TableTab>.from(state.openTabs)..add(newTab);

    emit(state.copyWith(
      openTabs: updatedTabs,
      activeTabId: tabId,
    ));

    // Load relation data
    try {
      final response = await apiService.get(
        '/api/data-management/tables/${event.sourceSchema}/${event.sourceTable}/relations/${event.sourceColumn}/${event.relationValue}',
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final relatedTableData = PaginatedTableData.fromJson(data);

        // Also get table details for the related table
        final detailsResponse = await apiService.get(
          '/api/data-management/tables/${event.targetSchema}/${event.targetTable}/info',
        );

        if (detailsResponse.statusCode == 200) {
          final tableDetails =
              TableDetails.fromJson(detailsResponse.data['data']);

          final updatedTab = newTab.copyWith(
            isLoading: false,
            tableDetails: tableDetails,
            tableData: relatedTableData,
          );

          final finalTabs = state.openTabs
              .map((tab) => tab.id == tabId ? updatedTab : tab)
              .toList();

          emit(state.copyWith(openTabs: finalTabs));
        }
      }
    } catch (e) {
      // Handle error - update tab with error state
      final errorTab = newTab.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );

      final finalTabs = state.openTabs
          .map((tab) => tab.id == tabId ? errorTab : tab)
          .toList();

      emit(state.copyWith(openTabs: finalTabs));
    }
  }

  Future<void> _onLoadRelationData(
    LoadRelationData event,
    Emitter<DataManagementState> emit,
  ) async {
    try {
      final response = await apiService.get(
        '/api/data-management/tables/${event.sourceSchema}/${event.sourceTable}/relations/${event.sourceColumn}/${event.relationValue}',
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final relatedTableData = PaginatedTableData.fromJson(data);

        emit(state.copyWith(
          tableData: relatedTableData,
          status: DataManagementStatus.loaded,
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: DataManagementStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  void _onResetDataManagement(
    ResetDataManagement event,
    Emitter<DataManagementState> emit,
  ) {
    emit(const DataManagementState.initial());
  }

  // Reverse Relation Event Handlers
  Future<void> _onOpenReverseRelationDialog(
    OpenReverseRelationDialog event,
    Emitter<DataManagementState> emit,
  ) async {
    try {
      // print('[DataManagementBloc] Opening reverse relation dialog...');
      // print(
      //     '[DataManagementBloc] Source: ${event.sourceSchema}.${event.sourceTable}');
      // print(
      //     '[DataManagementBloc] Target: ${event.referencingSchema}.${event.referencingTable}');
      // print('[DataManagementBloc] Record ID: ${event.recordId}');

      emit(state.copyWith(
        isReverseRelationDialogOpen: true,
        isLoadingReverseRelation: true,
      ));

      // Ensure all parameters are strings
      final sourceSchema = event.sourceSchema.toString();
      final sourceTable = event.sourceTable.toString();
      final referencedColumn = event.referencedColumn.toString();
      final recordId = event.recordId.toString();
      final referencingSchema = event.referencingSchema.toString();
      final referencingTable = event.referencingTable.toString();
      final referencingColumn = event.referencingColumn.toString();

      final response = await apiService.get(
        '/api/data-management/tables/$sourceSchema/$sourceTable/reverse-relations/$referencedColumn/$recordId',
        queryParameters: {
          'referencingSchema': referencingSchema,
          'referencingTable': referencingTable,
          'referencingColumn': referencingColumn,
          'limit': 50, // Keep as integer
        },
      );

      // print('[DataManagementBloc] API Response Status: ${response.statusCode}');
      // print('[DataManagementBloc] API Response Data: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;

        // Safely extract data and totalCount
        List<Map<String, dynamic>> records = [];
        int totalCount = 0;

        if (data is Map<String, dynamic>) {
          if (data.containsKey('data') && data['data'] is List) {
            records = (data['data'] as List).map((item) {
              if (item is Map<String, dynamic>) {
                return item;
              } else if (item is Map) {
                return Map<String, dynamic>.from(item);
              } else {
                return <String, dynamic>{'value': item.toString()};
              }
            }).toList();
          }

          totalCount = (data['totalCount'] as num?)?.toInt() ?? records.length;
        }

        final reverseRelationData = ReverseRelationData(
          referencingTable: referencingTable,
          referencingSchema: referencingSchema,
          referencingColumn: referencingColumn,
          relatedRecords: records,
          totalCount: totalCount,
        );

        // print(
        //     '[DataManagementBloc] ✅ Loaded ${reverseRelationData.relatedRecords.length} records');

        emit(state.copyWith(
          reverseRelationData: reverseRelationData,
          isLoadingReverseRelation: false,
        ));
      } else {
        // print('[DataManagementBloc] ❌ API Error: ${response.statusCode}');
        emit(state.copyWith(
          isLoadingReverseRelation: false,
          errorMessage: 'Failed to load reverse relation data',
        ));
      }
    } catch (e) {
              // print('[DataManagementBloc] ❌ Exception: $e');
      emit(state.copyWith(
        isLoadingReverseRelation: false,
        errorMessage: e.toString(),
      ));
    }
  }

  void _onCloseReverseRelationDialog(
    CloseReverseRelationDialog event,
    Emitter<DataManagementState> emit,
  ) {
    emit(state.copyWith(
      isReverseRelationDialogOpen: false,
      reverseRelationData: null,
      isLoadingReverseRelation: false,
    ));
  }
}
