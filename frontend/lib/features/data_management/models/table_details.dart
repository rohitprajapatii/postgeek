import 'package:equatable/equatable.dart';

class TableDetails extends Equatable {
  final String tableName;
  final String schemaName;
  final int rowCount;
  final List<ColumnInfo> columns;
  final List<String> primaryKeys;
  final List<ForeignKeyInfo> foreignKeys;
  final List<IndexInfo> indexes;

  const TableDetails({
    required this.tableName,
    required this.schemaName,
    required this.rowCount,
    required this.columns,
    required this.primaryKeys,
    required this.foreignKeys,
    required this.indexes,
  });

  factory TableDetails.fromJson(Map<String, dynamic> json) {
    return TableDetails(
      tableName: json['tableName'] as String,
      schemaName: json['schemaName'] as String,
      rowCount: json['rowCount'] as int? ?? 0,
      columns: (json['columns'] as List? ?? [])
          .map((column) => ColumnInfo.fromJson(column))
          .toList(),
      primaryKeys: List<String>.from(json['primaryKeys'] as List? ?? []),
      foreignKeys: (json['foreignKeys'] as List? ?? [])
          .map((fk) => ForeignKeyInfo.fromJson(fk))
          .toList(),
      indexes: (json['indexes'] as List? ?? [])
          .map((index) => IndexInfo.fromJson(index))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [
        tableName,
        schemaName,
        rowCount,
        columns,
        primaryKeys,
        foreignKeys,
        indexes,
      ];
}

class ColumnInfo extends Equatable {
  final String columnName;
  final String dataType;
  final bool isNullable;
  final String? defaultValue;
  final int? maxLength;
  final int? precision;
  final int? scale;
  final bool isIdentity;
  final bool isPrimaryKey;
  final bool isForeignKey;
  final ForeignKeyReference? references;

  const ColumnInfo({
    required this.columnName,
    required this.dataType,
    required this.isNullable,
    this.defaultValue,
    this.maxLength,
    this.precision,
    this.scale,
    required this.isIdentity,
    required this.isPrimaryKey,
    required this.isForeignKey,
    this.references,
  });

  factory ColumnInfo.fromJson(Map<String, dynamic> json) {
    return ColumnInfo(
      columnName: json['columnName'] as String,
      dataType: json['dataType'] as String,
      isNullable: json['isNullable'] as bool? ?? false,
      defaultValue: json['defaultValue'] as String?,
      maxLength: json['maxLength'] as int?,
      precision: json['precision'] as int?,
      scale: json['scale'] as int?,
      isIdentity: json['isIdentity'] as bool? ?? false,
      isPrimaryKey: json['isPrimaryKey'] as bool? ?? false,
      isForeignKey: json['isForeignKey'] as bool? ?? false,
      references: json['references'] != null
          ? ForeignKeyReference.fromJson(json['references'])
          : null,
    );
  }

  @override
  List<Object?> get props => [
        columnName,
        dataType,
        isNullable,
        defaultValue,
        maxLength,
        precision,
        scale,
        isIdentity,
        isPrimaryKey,
        isForeignKey,
        references,
      ];
}

class ForeignKeyReference extends Equatable {
  final String table;
  final String column;
  final String schema;

  const ForeignKeyReference({
    required this.table,
    required this.column,
    required this.schema,
  });

  factory ForeignKeyReference.fromJson(Map<String, dynamic> json) {
    return ForeignKeyReference(
      table: json['table'] as String,
      column: json['column'] as String,
      schema: json['schema'] as String,
    );
  }

  @override
  List<Object?> get props => [table, column, schema];
}

class ForeignKeyInfo extends Equatable {
  final String constraintName;
  final String columnName;
  final String referencedTable;
  final String referencedColumn;
  final String referencedSchema;

  const ForeignKeyInfo({
    required this.constraintName,
    required this.columnName,
    required this.referencedTable,
    required this.referencedColumn,
    required this.referencedSchema,
  });

  factory ForeignKeyInfo.fromJson(Map<String, dynamic> json) {
    return ForeignKeyInfo(
      constraintName: json['constraintName'] as String,
      columnName: json['columnName'] as String,
      referencedTable: json['referencedTable'] as String,
      referencedColumn: json['referencedColumn'] as String,
      referencedSchema: json['referencedSchema'] as String,
    );
  }

  @override
  List<Object?> get props => [
        constraintName,
        columnName,
        referencedTable,
        referencedColumn,
        referencedSchema,
      ];
}

class IndexInfo extends Equatable {
  final String indexName;
  final List<String> columns;
  final bool isUnique;
  final bool isPrimary;

  const IndexInfo({
    required this.indexName,
    required this.columns,
    required this.isUnique,
    required this.isPrimary,
  });

  factory IndexInfo.fromJson(Map<String, dynamic> json) {
    return IndexInfo(
      indexName: json['indexName'] as String,
      columns: List<String>.from(json['columns'] as List? ?? []),
      isUnique: json['isUnique'] as bool? ?? false,
      isPrimary: json['isPrimary'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [indexName, columns, isUnique, isPrimary];
}
