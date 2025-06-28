export interface TableInfo {
  tableName: string;
  schemaName: string;
  rowCount: number;
  columns: ColumnInfo[];
  primaryKeys: string[];
  foreignKeys: ForeignKeyInfo[];
  indexes: IndexInfo[];
}

export interface ColumnInfo {
  columnName: string;
  dataType: string;
  isNullable: boolean;
  defaultValue: string | null;
  maxLength: number | null;
  precision: number | null;
  scale: number | null;
  isIdentity: boolean;
  isPrimaryKey: boolean;
  isForeignKey: boolean;
  references?: {
    table: string;
    column: string;
    schema: string;
  };
}

export interface ForeignKeyInfo {
  constraintName: string;
  columnName: string;
  referencedTable: string;
  referencedColumn: string;
  referencedSchema: string;
}

export interface IndexInfo {
  indexName: string;
  columns: string[];
  isUnique: boolean;
  isPrimary: boolean;
}

export interface SchemaInfo {
  schemaName: string;
  tables: {
    tableName: string;
    rowCount: number;
  }[];
}

export interface QueryResult {
  rows: any[];
  fields: {
    name: string;
    dataTypeID: number;
    dataType: string;
  }[];
  rowCount: number;
  executionTime: number;
}

export interface PaginatedResult<T> {
  data: T[];
  pagination: {
    page: number;
    limit: number;
    total: number;
    totalPages: number;
  };
}

export interface DataValidationError {
  column: string;
  value: any;
  error: string;
}

export interface BulkOperationResult {
  success: boolean;
  processedCount: number;
  errors: DataValidationError[];
  insertedIds?: any[];
}
