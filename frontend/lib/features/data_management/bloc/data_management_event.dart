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
  List<Object> get props => [searchTerm];
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
  List<Object> get props => [schemaName, tableName];
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

// New tab management events
class OpenTableTab extends DataManagementEvent {
  final String schemaName;
  final String tableName;

  const OpenTableTab({
    required this.schemaName,
    required this.tableName,
  });

  @override
  List<Object> get props => [schemaName, tableName];
}

class CloseTableTab extends DataManagementEvent {
  final String tabId;

  const CloseTableTab(this.tabId);

  @override
  List<Object> get props => [tabId];
}

class SwitchToTab extends DataManagementEvent {
  final String tabId;

  const SwitchToTab(this.tabId);

  @override
  List<Object> get props => [tabId];
}

class ReorderTabs extends DataManagementEvent {
  final int oldIndex;
  final int newIndex;

  const ReorderTabs({
    required this.oldIndex,
    required this.newIndex,
  });

  @override
  List<Object> get props => [oldIndex, newIndex];
}

class RefreshTabData extends DataManagementEvent {
  final String tabId;

  const RefreshTabData(this.tabId);

  @override
  List<Object> get props => [tabId];
}

// CRUD Events
class CreateRecord extends DataManagementEvent {
  final String schemaName;
  final String tableName;
  final Map<String, dynamic> record;

  const CreateRecord({
    required this.schemaName,
    required this.tableName,
    required this.record,
  });

  @override
  List<Object> get props => [schemaName, tableName, record];
}

class UpdateRecord extends DataManagementEvent {
  final String schemaName;
  final String tableName;
  final Map<String, dynamic> record;
  final Map<String, dynamic> primaryKey;

  const UpdateRecord({
    required this.schemaName,
    required this.tableName,
    required this.record,
    required this.primaryKey,
  });

  @override
  List<Object> get props => [schemaName, tableName, record, primaryKey];
}

class DeleteRecord extends DataManagementEvent {
  final String schemaName;
  final String tableName;
  final Map<String, dynamic> primaryKey;

  const DeleteRecord({
    required this.schemaName,
    required this.tableName,
    required this.primaryKey,
  });

  @override
  List<Object> get props => [schemaName, tableName, primaryKey];
}

// Bulk Operations
class BulkInsertRecords extends DataManagementEvent {
  final String schemaName;
  final String tableName;
  final List<Map<String, dynamic>> records;

  const BulkInsertRecords({
    required this.schemaName,
    required this.tableName,
    required this.records,
  });

  @override
  List<Object> get props => [schemaName, tableName, records];
}

// Query Events
class ExecuteQuery extends DataManagementEvent {
  final String query;

  const ExecuteQuery(this.query);

  @override
  List<Object> get props => [query];
}

// Export Events
class ExportTableData extends DataManagementEvent {
  final String schemaName;
  final String tableName;
  final String format;

  const ExportTableData({
    required this.schemaName,
    required this.tableName,
    required this.format,
  });

  @override
  List<Object> get props => [schemaName, tableName, format];
}

// Foreign Key Events
class LoadForeignKeyData extends DataManagementEvent {
  final String schemaName;
  final String tableName;
  final String columnName;

  const LoadForeignKeyData({
    required this.schemaName,
    required this.tableName,
    required this.columnName,
  });

  @override
  List<Object> get props => [schemaName, tableName, columnName];
}

// Reset Events
class ResetDataManagement extends DataManagementEvent {
  const ResetDataManagement();
}
