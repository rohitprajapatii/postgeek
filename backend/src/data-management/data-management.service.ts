import { Injectable, HttpException, HttpStatus } from "@nestjs/common";
import { DatabaseService } from "../database/database.service";
import {
  TableInfo,
  ColumnInfo,
  SchemaInfo,
  QueryResult,
  PaginatedResult,
  BulkOperationResult,
  DataValidationError,
  ForeignKeyInfo,
  IndexInfo,
} from "./interfaces/data-management.interface";
import {
  TableQueryDto,
  FilterCondition,
  CreateRecordDto,
  UpdateRecordDto,
  DeleteRecordDto,
  BulkOperationDto,
  QueryExecutionDto,
} from "./dto/table-query.dto";

@Injectable()
export class DataManagementService {
  constructor(private readonly databaseService: DatabaseService) {}

  /**
   * Check if database connection is available
   */
  private checkConnection(): void {
    const status = this.databaseService.getConnectionStatus();
    if (!status.isConnected) {
      throw new HttpException(
        "Database connection is not available",
        HttpStatus.SERVICE_UNAVAILABLE
      );
    }
  }

  /**
   * Quote PostgreSQL identifier (table name, column name, etc.) to preserve case sensitivity
   */
  private quoteIdentifier(identifier: string): string {
    return `"${identifier.replace(/"/g, '""')}"`;
  }

  /**
   * Build a qualified table name with proper quoting
   */
  private getQualifiedTableName(schemaName: string, tableName: string): string {
    return `${this.quoteIdentifier(schemaName)}.${this.quoteIdentifier(tableName)}`;
  }

  /**
   * Get all schemas and their tables
   */
  async getSchemas(): Promise<SchemaInfo[]> {
    this.checkConnection();
    const query = `
      SELECT 
        pt.schemaname as schema_name,
        pt.tablename as table_name,
        COALESCE(pst.n_tup_ins + pst.n_tup_upd + pst.n_tup_del, 0) as estimated_rows
      FROM pg_tables pt
      LEFT JOIN pg_stat_user_tables pst ON pt.tablename = pst.relname AND pt.schemaname = pst.schemaname
      WHERE pt.schemaname NOT IN ('information_schema', 'pg_catalog', 'pg_toast')
      ORDER BY pt.schemaname, pt.tablename;
    `;

    const result = await this.databaseService.query(query);
    const schemaMap = new Map<string, SchemaInfo>();

    result.rows.forEach((row) => {
      const schemaName = row.schema_name;
      if (!schemaMap.has(schemaName)) {
        schemaMap.set(schemaName, {
          schemaName,
          tables: [],
        });
      }
      schemaMap.get(schemaName)!.tables.push({
        tableName: row.table_name,
        rowCount: parseInt(row.estimated_rows) || 0,
      });
    });

    return Array.from(schemaMap.values());
  }

  /**
   * Get detailed table information including columns, constraints, and indexes
   */
  async getTableInfo(
    schemaName: string,
    tableName: string
  ): Promise<TableInfo> {
    this.checkConnection();
    const [columns, foreignKeys, indexes, rowCount] = await Promise.all([
      this.getTableColumns(schemaName, tableName),
      this.getTableForeignKeys(schemaName, tableName),
      this.getTableIndexes(schemaName, tableName),
      this.getTableRowCount(schemaName, tableName),
    ]);

    const primaryKeys = columns
      .filter((col) => col.isPrimaryKey)
      .map((col) => col.columnName);

    return {
      tableName,
      schemaName,
      rowCount,
      columns,
      primaryKeys,
      foreignKeys,
      indexes,
    };
  }

  /**
   * Get table data with pagination, sorting, and filtering
   */
  async getTableData(
    schemaName: string,
    tableName: string,
    queryOptions: TableQueryDto
  ): Promise<PaginatedResult<any>> {
    this.checkConnection();
    const {
      page = 1,
      limit = 50,
      sortBy,
      sortOrder = "ASC",
      filters,
    } = queryOptions;
    const offset = (page - 1) * limit;

    // Build WHERE clause from filters
    let whereClause = "";
    const queryParams: any[] = [];
    if (filters && filters.length > 0) {
      const conditions = filters.map((filter, index) => {
        const paramIndex = queryParams.length + 1;
        queryParams.push(this.formatFilterValue(filter));
        return `${this.quoteIdentifier(filter.column)} ${filter.operator} $${paramIndex}`;
      });
      whereClause = `WHERE ${conditions.join(" AND ")}`;
    }

    // Build ORDER BY clause
    let orderClause = "";
    if (sortBy) {
      orderClause = `ORDER BY ${this.quoteIdentifier(sortBy)} ${sortOrder}`;
    }

    const qualifiedTableName = this.getQualifiedTableName(
      schemaName,
      tableName
    );

    // Get total count
    const countQuery = `
      SELECT COUNT(*) as total 
      FROM ${qualifiedTableName} 
      ${whereClause}
    `;
    const countResult = await this.databaseService.query(
      countQuery,
      queryParams
    );
    const total = parseInt(countResult.rows[0].total);

    // Get paginated data
    const dataQuery = `
      SELECT * 
      FROM ${qualifiedTableName} 
      ${whereClause}
      ${orderClause}
      LIMIT $${queryParams.length + 1} OFFSET $${queryParams.length + 2}
    `;
    queryParams.push(limit, offset);

    const dataResult = await this.databaseService.query(dataQuery, queryParams);

    return {
      data: dataResult.rows,
      pagination: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  /**
   * Create a new record
   */
  async createRecord(
    schemaName: string,
    tableName: string,
    createDto: CreateRecordDto
  ): Promise<any> {
    this.checkConnection();
    const { data } = createDto;
    const columns = Object.keys(data);
    const values = Object.values(data);
    const placeholders = values.map((_, index) => `$${index + 1}`).join(", ");
    const quotedColumns = columns
      .map((col) => this.quoteIdentifier(col))
      .join(", ");
    const qualifiedTableName = this.getQualifiedTableName(
      schemaName,
      tableName
    );

    const query = `
      INSERT INTO ${qualifiedTableName} (${quotedColumns})
      VALUES (${placeholders})
      RETURNING *
    `;

    const result = await this.databaseService.query(query, values);
    return result.rows[0];
  }

  /**
   * Update records
   */
  async updateRecord(
    schemaName: string,
    tableName: string,
    updateDto: UpdateRecordDto
  ): Promise<any[]> {
    this.checkConnection();
    const { data, where } = updateDto;

    const setClause = Object.keys(data)
      .map((key, index) => `${this.quoteIdentifier(key)} = $${index + 1}`)
      .join(", ");

    const whereConditions = Object.keys(where)
      .map(
        (key, index) =>
          `${this.quoteIdentifier(key)} = $${Object.keys(data).length + index + 1}`
      )
      .join(" AND ");

    const values = [...Object.values(data), ...Object.values(where)];
    const qualifiedTableName = this.getQualifiedTableName(
      schemaName,
      tableName
    );

    const query = `
      UPDATE ${qualifiedTableName}
      SET ${setClause}
      WHERE ${whereConditions}
      RETURNING *
    `;

    const result = await this.databaseService.query(query, values);
    return result.rows;
  }

  /**
   * Delete records
   */
  async deleteRecord(
    schemaName: string,
    tableName: string,
    deleteDto: DeleteRecordDto
  ): Promise<number> {
    const { where } = deleteDto;

    const whereConditions = Object.keys(where)
      .map((key, index) => `${this.quoteIdentifier(key)} = $${index + 1}`)
      .join(" AND ");

    const values = Object.values(where);
    const qualifiedTableName = this.getQualifiedTableName(
      schemaName,
      tableName
    );

    const query = `
      DELETE FROM ${qualifiedTableName}
      WHERE ${whereConditions}
    `;

    const result = await this.databaseService.query(query, values);
    return result.rowCount || 0;
  }

  /**
   * Bulk insert records
   */
  async bulkInsert(
    schemaName: string,
    tableName: string,
    bulkDto: BulkOperationDto
  ): Promise<BulkOperationResult> {
    const { records, upsert } = bulkDto;
    const errors: DataValidationError[] = [];
    const insertedIds: any[] = [];
    let processedCount = 0;

    // Get table structure for validation
    const tableInfo = await this.getTableInfo(schemaName, tableName);

    for (const record of records) {
      try {
        // Validate record against table structure
        const validationErrors = await this.validateRecord(record, tableInfo);
        if (validationErrors.length > 0) {
          errors.push(...validationErrors);
          continue;
        }

        const columns = Object.keys(record);
        const values = Object.values(record);
        const placeholders = values
          .map((_, index) => `$${index + 1}`)
          .join(", ");

        const quotedColumns = columns.map((col) => this.quoteIdentifier(col));
        const qualifiedTableName = this.getQualifiedTableName(
          schemaName,
          tableName
        );

        let query: string;
        if (upsert && tableInfo.primaryKeys.length > 0) {
          const conflictColumns = tableInfo.primaryKeys
            .map((key) => this.quoteIdentifier(key))
            .join(", ");
          const updateClause = columns
            .filter((col) => !tableInfo.primaryKeys.includes(col))
            .map(
              (col) =>
                `${this.quoteIdentifier(col)} = EXCLUDED.${this.quoteIdentifier(col)}`
            )
            .join(", ");

          query = `
            INSERT INTO ${qualifiedTableName} (${quotedColumns.join(", ")})
            VALUES (${placeholders})
            ON CONFLICT (${conflictColumns})
            DO UPDATE SET ${updateClause}
            RETURNING *
          `;
        } else {
          query = `
            INSERT INTO ${qualifiedTableName} (${quotedColumns.join(", ")})
            VALUES (${placeholders})
            RETURNING *
          `;
        }

        const result = await this.databaseService.query(query, values);
        insertedIds.push(...result.rows);
        processedCount++;
      } catch (error) {
        errors.push({
          column: "general",
          value: record,
          error: error.message,
        });
      }
    }

    return {
      success: errors.length === 0,
      processedCount,
      errors,
      insertedIds,
    };
  }

  /**
   * Execute custom SQL query
   */
  async executeQuery(queryDto: QueryExecutionDto): Promise<QueryResult> {
    this.checkConnection();
    const { query, params = [], readonly = true } = queryDto;

    // Basic SQL injection protection for readonly queries
    if (readonly && this.containsWriteOperations(query)) {
      throw new HttpException(
        "Write operations not allowed in readonly mode",
        HttpStatus.BAD_REQUEST
      );
    }

    const startTime = Date.now();
    const result = await this.databaseService.query(query, params);
    const executionTime = Date.now() - startTime;

    return {
      rows: result.rows,
      fields: result.fields || [],
      rowCount: result.rowCount || 0,
      executionTime,
    };
  }

  /**
   * Get foreign key referenced data for a specific value
   */
  async getForeignKeyData(
    referencedSchema: string,
    referencedTable: string,
    referencedColumn: string,
    value: any
  ): Promise<any[]> {
    const qualifiedTableName = this.getQualifiedTableName(
      referencedSchema,
      referencedTable
    );
    const quotedColumn = this.quoteIdentifier(referencedColumn);

    const query = `
      SELECT * FROM ${qualifiedTableName}
      WHERE ${quotedColumn} = $1
      LIMIT 10
    `;

    const result = await this.databaseService.query(query, [value]);
    return result.rows;
  }

  /**
   * Export table data to CSV format
   */
  async exportTableData(
    schemaName: string,
    tableName: string,
    format: "csv" | "json" = "csv",
    filters?: FilterCondition[]
  ): Promise<string> {
    let whereClause = "";
    const queryParams: any[] = [];

    if (filters && filters.length > 0) {
      const conditions = filters.map((filter, index) => {
        const paramIndex = queryParams.length + 1;
        queryParams.push(this.formatFilterValue(filter));
        return `${this.quoteIdentifier(filter.column)} ${filter.operator} $${paramIndex}`;
      });
      whereClause = `WHERE ${conditions.join(" AND ")}`;
    }

    const qualifiedTableName = this.getQualifiedTableName(
      schemaName,
      tableName
    );
    const query = `SELECT * FROM ${qualifiedTableName} ${whereClause}`;
    const result = await this.databaseService.query(query, queryParams);

    if (format === "json") {
      return JSON.stringify(result.rows, null, 2);
    }

    // CSV format
    if (result.rows.length === 0) return "";

    const headers = Object.keys(result.rows[0]);
    const csvRows = [
      headers.join(","),
      ...result.rows.map((row) =>
        headers
          .map((header) => {
            const value = row[header];
            if (value === null || value === undefined) return "";
            if (typeof value === "string" && value.includes(",")) {
              return `"${value.replace(/"/g, '""')}"`;
            }
            return value;
          })
          .join(",")
      ),
    ];

    return csvRows.join("\n");
  }

  // Private helper methods

  private async getTableColumns(
    schemaName: string,
    tableName: string
  ): Promise<ColumnInfo[]> {
    const query = `
      SELECT 
        c.column_name,
        c.data_type,
        c.is_nullable::boolean,
        c.column_default,
        c.character_maximum_length,
        c.numeric_precision,
        c.numeric_scale,
        c.is_identity::boolean,
        CASE WHEN kcu.column_name IS NOT NULL THEN true ELSE false END as is_primary_key,
        CASE WHEN fkc.column_name IS NOT NULL THEN true ELSE false END as is_foreign_key,
        fkc.foreign_table_schema,
        fkc.foreign_table_name,
        fkc.foreign_column_name
      FROM information_schema.columns c
      LEFT JOIN information_schema.key_column_usage kcu ON 
        c.table_schema = kcu.table_schema AND 
        c.table_name = kcu.table_name AND 
        c.column_name = kcu.column_name
      LEFT JOIN information_schema.table_constraints tc ON 
        kcu.constraint_name = tc.constraint_name AND 
        tc.constraint_type = 'PRIMARY KEY'
      LEFT JOIN (
        SELECT
          kcu.column_name,
          kcu.table_schema,
          kcu.table_name,
          ccu.table_schema AS foreign_table_schema,
          ccu.table_name AS foreign_table_name,
          ccu.column_name AS foreign_column_name
        FROM information_schema.key_column_usage kcu
        JOIN information_schema.table_constraints tc ON 
          kcu.constraint_name = tc.constraint_name
        JOIN information_schema.constraint_column_usage ccu ON 
          ccu.constraint_name = tc.constraint_name
        WHERE tc.constraint_type = 'FOREIGN KEY'
      ) fkc ON 
        c.table_schema = fkc.table_schema AND 
        c.table_name = fkc.table_name AND 
        c.column_name = fkc.column_name
      WHERE c.table_schema = $1 AND c.table_name = $2
      ORDER BY c.ordinal_position;
    `;

    const result = await this.databaseService.query(query, [
      schemaName,
      tableName,
    ]);

    return result.rows.map((row) => ({
      columnName: row.column_name,
      dataType: row.data_type,
      isNullable: row.is_nullable === "YES",
      defaultValue: row.column_default,
      maxLength: row.character_maximum_length,
      precision: row.numeric_precision,
      scale: row.numeric_scale,
      isIdentity: row.is_identity === "YES",
      isPrimaryKey: row.is_primary_key,
      isForeignKey: row.is_foreign_key,
      references: row.is_foreign_key
        ? {
            table: row.foreign_table_name,
            column: row.foreign_column_name,
            schema: row.foreign_table_schema,
          }
        : undefined,
    }));
  }

  private async getTableForeignKeys(
    schemaName: string,
    tableName: string
  ): Promise<ForeignKeyInfo[]> {
    const query = `
      SELECT
        tc.constraint_name,
        kcu.column_name,
        ccu.table_schema AS foreign_table_schema,
        ccu.table_name AS foreign_table_name,
        ccu.column_name AS foreign_column_name
      FROM information_schema.table_constraints tc
      JOIN information_schema.key_column_usage kcu ON 
        tc.constraint_name = kcu.constraint_name
      JOIN information_schema.constraint_column_usage ccu ON 
        ccu.constraint_name = tc.constraint_name
      WHERE tc.constraint_type = 'FOREIGN KEY'
        AND tc.table_schema = $1
        AND tc.table_name = $2;
    `;

    const result = await this.databaseService.query(query, [
      schemaName,
      tableName,
    ]);

    return result.rows.map((row) => ({
      constraintName: row.constraint_name,
      columnName: row.column_name,
      referencedTable: row.foreign_table_name,
      referencedColumn: row.foreign_column_name,
      referencedSchema: row.foreign_table_schema,
    }));
  }

  private async getTableIndexes(
    schemaName: string,
    tableName: string
  ): Promise<IndexInfo[]> {
    const query = `
      SELECT
        i.indexname,
        i.indexdef,
        CASE WHEN i.indexname LIKE '%_pkey' THEN true ELSE false END as is_primary,
        CASE WHEN ix.indisunique THEN true ELSE false END as is_unique
      FROM pg_indexes i
      JOIN pg_class t ON t.relname = i.tablename
      JOIN pg_index ix ON ix.indexrelid = (
        SELECT oid FROM pg_class WHERE relname = i.indexname
      )
      WHERE i.schemaname = $1 AND i.tablename = $2;
    `;

    const result = await this.databaseService.query(query, [
      schemaName,
      tableName,
    ]);

    return result.rows.map((row) => {
      // Extract column names from index definition
      const columns = this.extractColumnsFromIndexDef(row.indexdef);

      return {
        indexName: row.indexname,
        columns,
        isUnique: row.is_unique,
        isPrimary: row.is_primary,
      };
    });
  }

  private async getTableRowCount(
    schemaName: string,
    tableName: string
  ): Promise<number> {
    const query = `
      SELECT n_tup_ins + n_tup_upd + n_tup_del as estimated_rows
      FROM pg_stat_user_tables
      WHERE schemaname = $1 AND relname = $2;
    `;

    const result = await this.databaseService.query(query, [
      schemaName,
      tableName,
    ]);
    return result.rows.length > 0
      ? parseInt(result.rows[0].estimated_rows) || 0
      : 0;
  }

  private formatFilterValue(filter: FilterCondition): any {
    const { operator, value } = filter;

    if (operator === "IN" || operator === "NOT IN") {
      return value.split(",").map((v) => v.trim());
    }

    if (operator === "LIKE" || operator === "ILIKE") {
      return `%${value}%`;
    }

    return value;
  }

  private async validateRecord(
    record: Record<string, any>,
    tableInfo: TableInfo
  ): Promise<DataValidationError[]> {
    const errors: DataValidationError[] = [];

    for (const column of tableInfo.columns) {
      const value = record[column.columnName];

      // Check required fields
      if (!column.isNullable && (value === null || value === undefined)) {
        errors.push({
          column: column.columnName,
          value,
          error: "Field is required",
        });
      }

      // Check data type constraints
      if (value !== null && value !== undefined) {
        const validationError = this.validateDataType(value, column);
        if (validationError) {
          errors.push({
            column: column.columnName,
            value,
            error: validationError,
          });
        }
      }
    }

    return errors;
  }

  private validateDataType(value: any, column: ColumnInfo): string | null {
    const { dataType, maxLength } = column;

    switch (dataType) {
      case "integer":
      case "bigint":
      case "smallint":
        if (!Number.isInteger(Number(value))) {
          return "Value must be an integer";
        }
        break;

      case "numeric":
      case "decimal":
      case "real":
      case "double precision":
        if (isNaN(Number(value))) {
          return "Value must be a number";
        }
        break;

      case "character varying":
      case "varchar":
      case "text":
        if (typeof value !== "string") {
          return "Value must be a string";
        }
        if (maxLength && value.length > maxLength) {
          return `Value exceeds maximum length of ${maxLength}`;
        }
        break;

      case "boolean":
        if (
          typeof value !== "boolean" &&
          value !== "true" &&
          value !== "false"
        ) {
          return "Value must be true or false";
        }
        break;

      case "date":
        if (!this.isValidDate(value)) {
          return "Value must be a valid date";
        }
        break;

      case "timestamp":
      case "timestamp with time zone":
        if (!this.isValidTimestamp(value)) {
          return "Value must be a valid timestamp";
        }
        break;
    }

    return null;
  }

  private containsWriteOperations(query: string): boolean {
    const writeKeywords = [
      "INSERT",
      "UPDATE",
      "DELETE",
      "DROP",
      "CREATE",
      "ALTER",
      "TRUNCATE",
    ];
    const upperQuery = query.toUpperCase();
    return writeKeywords.some((keyword) => upperQuery.includes(keyword));
  }

  private extractColumnsFromIndexDef(indexDef: string): string[] {
    // Simple regex to extract column names from CREATE [UNIQUE] INDEX ... USING ... (columns)
    const match = indexDef.match(/\(([^)]+)\)/);
    if (match) {
      return match[1].split(",").map((col) => col.trim().replace(/"/g, ""));
    }
    return [];
  }

  private isValidDate(value: any): boolean {
    const date = new Date(value);
    return date instanceof Date && !isNaN(date.getTime());
  }

  private isValidTimestamp(value: any): boolean {
    return this.isValidDate(value);
  }
}
