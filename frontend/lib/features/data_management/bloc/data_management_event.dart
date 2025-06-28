part of 'data_management_bloc.dart';

abstract class DataManagementEvent extends Equatable {
  const DataManagementEvent();

  @override
  List<Object?> get props => [];
}

// Schema Events
class LoadSchemas extends DataManagementEvent {
  const LoadSchemas();
}

class SearchTables extends DataManagementEvent {
  final String searchTerm;

  const SearchTables(this.searchTerm);

  @override
  List<Object?> get props => [searchTerm];
}

// Table Events
class LoadTableDetails extends DataManagementEvent {
  final String schemaName;
  final String tableName;

  const LoadTableDetails({
    required this.schemaName,
    required this.tableName,
  });

  @override
  List<Object?> get props => [schemaName, tableName];
}

class LoadTableData extends DataManagementEvent {
  final String schemaName;
  final String tableName;
  final TableQueryOptions? queryOptions;

  const LoadTableData({
    required this.schemaName,
    required this.tableName,
    this.queryOptions,
  });

  @override
  List<Object?> get props => [schemaName, tableName, queryOptions];
}

// CRUD Events
class CreateRecord extends DataManagementEvent {
  final String schemaName;
  final String tableName;
  final Map<String, dynamic> data;

  const CreateRecord({
    required this.schemaName,
    required this.tableName,
    required this.data,
  });

  @override
  List<Object?> get props => [schemaName, tableName, data];
}

class UpdateRecord extends DataManagementEvent {
  final String schemaName;
  final String tableName;
  final Map<String, dynamic> data;
  final Map<String, dynamic> where;

  const UpdateRecord({
    required this.schemaName,
    required this.tableName,
    required this.data,
    required this.where,
  });

  @override
  List<Object?> get props => [schemaName, tableName, data, where];
}

class DeleteRecord extends DataManagementEvent {
  final String schemaName;
  final String tableName;
  final Map<String, dynamic> where;

  const DeleteRecord({
    required this.schemaName,
    required this.tableName,
    required this.where,
  });

  @override
  List<Object?> get props => [schemaName, tableName, where];
}

// Bulk Operations
class BulkInsertRecords extends DataManagementEvent {
  final String schemaName;
  final String tableName;
  final List<Map<String, dynamic>> records;
  final bool upsert;

  const BulkInsertRecords({
    required this.schemaName,
    required this.tableName,
    required this.records,
    this.upsert = false,
  });

  @override
  List<Object?> get props => [schemaName, tableName, records, upsert];
}

// Query Events
class ExecuteQuery extends DataManagementEvent {
  final String query;
  final List<dynamic> params;
  final bool readonly;

  const ExecuteQuery({
    required this.query,
    this.params = const [],
    this.readonly = true,
  });

  @override
  List<Object?> get props => [query, params, readonly];
}

// Export Events
class ExportTableData extends DataManagementEvent {
  final String schemaName;
  final String tableName;
  final String format;
  final List<FilterCondition> filters;

  const ExportTableData({
    required this.schemaName,
    required this.tableName,
    this.format = 'csv',
    this.filters = const [],
  });

  @override
  List<Object?> get props => [schemaName, tableName, format, filters];
}

// Foreign Key Events
class LoadForeignKeyData extends DataManagementEvent {
  final String schemaName;
  final String tableName;
  final String columnName;
  final dynamic value;

  const LoadForeignKeyData({
    required this.schemaName,
    required this.tableName,
    required this.columnName,
    required this.value,
  });

  @override
  List<Object?> get props => [schemaName, tableName, columnName, value];
}

// Reset Events
class ResetDataManagement extends DataManagementEvent {
  const ResetDataManagement();
}
