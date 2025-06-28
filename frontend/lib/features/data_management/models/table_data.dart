import 'package:equatable/equatable.dart';

class PaginatedTableData extends Equatable {
  final List<Map<String, dynamic>> data;
  final PaginationInfo pagination;

  const PaginatedTableData({
    required this.data,
    required this.pagination,
  });

  factory PaginatedTableData.fromJson(Map<String, dynamic> json) {
    return PaginatedTableData(
      data: List<Map<String, dynamic>>.from(json['data'] as List? ?? []),
      pagination: PaginationInfo.fromJson(json['pagination'] ?? {}),
    );
  }

  @override
  List<Object?> get props => [data, pagination];
}

class PaginationInfo extends Equatable {
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  const PaginationInfo({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  factory PaginationInfo.fromJson(Map<String, dynamic> json) {
    return PaginationInfo(
      page: json['page'] as int? ?? 1,
      limit: json['limit'] as int? ?? 50,
      total: json['total'] as int? ?? 0,
      totalPages: json['totalPages'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [page, limit, total, totalPages];
}

class FilterCondition extends Equatable {
  final String column;
  final String operator;
  final String value;
  final String logicalOperator;

  const FilterCondition({
    required this.column,
    required this.operator,
    required this.value,
    this.logicalOperator = 'AND',
  });

  factory FilterCondition.fromJson(Map<String, dynamic> json) {
    return FilterCondition(
      column: json['column'] as String,
      operator: json['operator'] as String,
      value: json['value'] as String,
      logicalOperator: json['logicalOperator'] as String? ?? 'AND',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'column': column,
      'operator': operator,
      'value': value,
      'logicalOperator': logicalOperator,
    };
  }

  @override
  List<Object?> get props => [column, operator, value, logicalOperator];
}

class TableQueryOptions extends Equatable {
  final int page;
  final int limit;
  final String? sortBy;
  final String sortOrder;
  final List<FilterCondition> filters;

  const TableQueryOptions({
    this.page = 1,
    this.limit = 50,
    this.sortBy,
    this.sortOrder = 'ASC',
    this.filters = const [],
  });

  Map<String, dynamic> toQueryParameters() {
    final params = <String, dynamic>{
      'page': page.toString(),
      'limit': limit.toString(),
      'sortOrder': sortOrder,
    };

    if (sortBy != null) {
      params['sortBy'] = sortBy!;
    }

    if (filters.isNotEmpty) {
      // Note: In a real implementation, you might need to serialize filters differently
      // depending on your backend API expectations
      params['filters'] = filters.map((f) => f.toJson()).toList();
    }

    return params;
  }

  TableQueryOptions copyWith({
    int? page,
    int? limit,
    String? sortBy,
    String? sortOrder,
    List<FilterCondition>? filters,
  }) {
    return TableQueryOptions(
      page: page ?? this.page,
      limit: limit ?? this.limit,
      sortBy: sortBy ?? this.sortBy,
      sortOrder: sortOrder ?? this.sortOrder,
      filters: filters ?? this.filters,
    );
  }

  @override
  List<Object?> get props => [page, limit, sortBy, sortOrder, filters];
}

class QueryResult extends Equatable {
  final List<Map<String, dynamic>> rows;
  final List<QueryField> fields;
  final int rowCount;
  final int executionTime;

  const QueryResult({
    required this.rows,
    required this.fields,
    required this.rowCount,
    required this.executionTime,
  });

  factory QueryResult.fromJson(Map<String, dynamic> json) {
    return QueryResult(
      rows: List<Map<String, dynamic>>.from(json['rows'] as List? ?? []),
      fields: (json['fields'] as List? ?? [])
          .map((field) => QueryField.fromJson(field))
          .toList(),
      rowCount: json['rowCount'] as int? ?? 0,
      executionTime: json['executionTime'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [rows, fields, rowCount, executionTime];
}

class QueryField extends Equatable {
  final String name;
  final int dataTypeID;
  final String dataType;

  const QueryField({
    required this.name,
    required this.dataTypeID,
    required this.dataType,
  });

  factory QueryField.fromJson(Map<String, dynamic> json) {
    return QueryField(
      name: json['name'] as String,
      dataTypeID: json['dataTypeID'] as int,
      dataType: json['dataType'] as String,
    );
  }

  @override
  List<Object?> get props => [name, dataTypeID, dataType];
}
