import 'package:equatable/equatable.dart';

class SchemaInfo extends Equatable {
  final String schemaName;
  final List<TableInfo> tables;

  const SchemaInfo({
    required this.schemaName,
    required this.tables,
  });

  factory SchemaInfo.fromJson(Map<String, dynamic> json) {
    return SchemaInfo(
      schemaName: json['schemaName'] as String,
      tables: (json['tables'] as List)
          .map((table) => TableInfo.fromJson(table))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'schemaName': schemaName,
      'tables': tables.map((table) => table.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [schemaName, tables];
}

class TableInfo extends Equatable {
  final String tableName;
  final int rowCount;

  const TableInfo({
    required this.tableName,
    required this.rowCount,
  });

  factory TableInfo.fromJson(Map<String, dynamic> json) {
    return TableInfo(
      tableName: json['tableName'] as String,
      rowCount: json['rowCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tableName': tableName,
      'rowCount': rowCount,
    };
  }

  @override
  List<Object?> get props => [tableName, rowCount];
}
