import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../core/services/api_service.dart';
import '../../connection/bloc/connection_bloc.dart';
import '../models/schema_info.dart';
import '../models/table_details.dart';
import '../models/table_data.dart';

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
    on<CreateRecord>(_onCreateRecord);
    on<UpdateRecord>(_onUpdateRecord);
    on<DeleteRecord>(_onDeleteRecord);
    on<BulkInsertRecords>(_onBulkInsertRecords);
    on<ExecuteQuery>(_onExecuteQuery);
    on<ExportTableData>(_onExportTableData);
    on<LoadForeignKeyData>(_onLoadForeignKeyData);
    on<ResetDataManagement>(_onResetDataManagement);
  }

  Future<void> _onLoadSchemas(
    LoadSchemas event,
    Emitter<DataManagementState> emit,
  ) async {
    try {
      emit(state.copyWith(status: DataManagementStatus.loading));

      print('[DataManagementBloc] Loading schemas...');

      final response = await apiService.get('/api/data-management/schemas');

      if (response.statusCode == 200) {
        final data = response.data;
        final List<SchemaInfo> schemas = (data['data'] as List)
            .map((schema) => SchemaInfo.fromJson(schema))
            .toList();

        print('[DataManagementBloc] ✅ Loaded ${schemas.length} schemas');

        emit(state.copyWith(
          status: DataManagementStatus.loaded,
          schemas: schemas,
          errorMessage: null,
        ));
      } else {
        final errorMessage = response.statusCode == 400
            ? 'Database not connected. Please establish a connection first.'
            : 'Failed to load schemas';

        print(
            '[DataManagementBloc] ❌ Error loading schemas: Status ${response.statusCode}');

        emit(state.copyWith(
          status: DataManagementStatus.error,
          errorMessage: errorMessage,
        ));
      }
    } catch (e) {
      print('[DataManagementBloc] ❌ Error loading schemas: $e');

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

  Future<void> _onCreateRecord(
    CreateRecord event,
    Emitter<DataManagementState> emit,
  ) async {
    try {
      final response = await apiService.post(
        '/api/data-management/tables/${event.schemaName}/${event.tableName}/records',
        data: {'data': event.data},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Reload table data to show the new record
        add(LoadTableData(
          schemaName: event.schemaName,
          tableName: event.tableName,
        ));
      } else {
        emit(state.copyWith(
          errorMessage: 'Failed to create record',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
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
          'data': event.data,
          'where': event.where,
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
          errorMessage: 'Failed to update record',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
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
        data: {'where': event.where},
      );

      if (response.statusCode == 200) {
        // Reload table data to reflect the deletion
        add(LoadTableData(
          schemaName: event.schemaName,
          tableName: event.tableName,
        ));
      } else {
        emit(state.copyWith(
          errorMessage: 'Failed to delete record',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
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
          'upsert': event.upsert,
        },
      );

      if (response.statusCode == 200) {
        // Reload table data to show the new records
        add(LoadTableData(
          schemaName: event.schemaName,
          tableName: event.tableName,
        ));
      } else {
        emit(state.copyWith(
          errorMessage: 'Bulk insert failed',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onExecuteQuery(
    ExecuteQuery event,
    Emitter<DataManagementState> emit,
  ) async {
    try {
      emit(state.copyWith(isExecutingQuery: true));

      final response = await apiService.post(
        '/api/data-management/query/execute',
        data: {
          'query': event.query,
          'params': event.params,
          'readonly': event.readonly,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final queryResult = QueryResult.fromJson(data['data']);

        emit(state.copyWith(
          queryResult: queryResult,
          isExecutingQuery: false,
          errorMessage: null,
        ));
      } else {
        emit(state.copyWith(
          isExecutingQuery: false,
          errorMessage: 'Query execution failed',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        isExecutingQuery: false,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onExportTableData(
    ExportTableData event,
    Emitter<DataManagementState> emit,
  ) async {
    try {
      emit(state.copyWith(isExporting: true));

      final response = await apiService.post(
        '/api/data-management/tables/${event.schemaName}/${event.tableName}/export',
        data: {
          'format': event.format,
          'filters': event.filters.map((f) => f.toJson()).toList(),
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final exportData = data['data'] as String;

        emit(state.copyWith(
          exportData: exportData,
          isExporting: false,
          errorMessage: null,
        ));
      } else {
        emit(state.copyWith(
          isExporting: false,
          errorMessage: 'Export failed',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        isExporting: false,
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
        '/api/data-management/foreign-key-data/${event.schemaName}/${event.tableName}/${event.columnName}',
        queryParameters: {'value': event.value.toString()},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final foreignKeyData = List<Map<String, dynamic>>.from(data['data']);

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

  Future<void> _onResetDataManagement(
    ResetDataManagement event,
    Emitter<DataManagementState> emit,
  ) async {
    emit(const DataManagementState.initial());
  }
}
