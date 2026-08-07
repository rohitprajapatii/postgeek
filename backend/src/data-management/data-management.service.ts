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

  // Allowed comparison operators for filters. Anything else is rejected to
  // prevent operator injection into interpolated SQL.
  private static readonly ALLOWED_OPERATORS = new Set([
    "=",
    "!=",
    "<>",
    ">",
    "<",
    ">=",
    "<=",
    "LIKE",
    "ILIKE",
    "NOT LIKE",
    "NOT ILIKE",
    "IN",
    "NOT IN",
    "IS",
    "IS NOT",
  ]);

  private safeOperator(operator: string): string {
    const op = (operator || "").trim().toUpperCase();
    // Symbolic operators keep their original form; word operators are upper-cased.
    const candidate = ["=", "!=", "<>", ">", "<", ">=", "<="].includes(operator?.trim())
      ? operator.trim()
      : op;
    if (!DataManagementService.ALLOWED_OPERATORS.has(candidate)) {
      throw new HttpException(
        `Unsupported filter operator: ${operator}`,
        HttpStatus.BAD_REQUEST
      );
    }
    return candidate;
  }

  private safeSortOrder(sortOrder?: string): "ASC" | "DESC" {
    return (sortOrder || "").toUpperCase() === "DESC" ? "DESC" : "ASC";
  }

  /**
   * Get all schemas and their tables
   */
  async getSchemas(): Promise<SchemaInfo[]> {
    this.checkConnection();
    // Planner estimate (reltuples) keeps the schema tree fast on large
    // databases. An exact COUNT(*) per table would be O(tables) sequential
    // scans just to render the sidebar.
    const query = `
      SELECT
        n.nspname AS schema_name,
        c.relname AS table_name,
        GREATEST(c.reltuples, 0)::bigint AS estimated_rows
      FROM pg_class c
      JOIN pg_namespace n ON n.oid = c.relnamespace
      WHERE c.relkind IN ('r', 'p')
        AND n.nspname NOT IN ('information_schema', 'pg_catalog', 'pg_toast')
        AND has_table_privilege(c.oid, 'SELECT')
      ORDER BY n.nspname, c.relname;
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
      const conditions = filters.map((filter) => {
        const paramIndex = queryParams.length + 1;
        queryParams.push(this.formatFilterValue(filter));
        return `${this.quoteIdentifier(filter.column)} ${this.safeOperator(filter.operator)} $${paramIndex}`;
      });
      whereClause = `WHERE ${conditions.join(" AND ")}`;
    }

    // Build ORDER BY clause
    let orderClause = "";
    if (sortBy) {
      orderClause = `ORDER BY ${this.quoteIdentifier(sortBy)} ${this.safeSortOrder(sortOrder)}`;
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

    // Relation metadata. Only the column list is needed here, so we avoid the
    // full getTableInfo() round trip (which would repeat the COUNT(*) above).
    const [columnInfo, reverseRelations] = await Promise.all([
      this.getTableColumns(schemaName, tableName),
      this.getReverseRelations(schemaName, tableName),
    ]);
    const foreignKeyColumns = columnInfo.filter(
      (col) => col.isForeignKey && col.references
    );

    // Resolve every relation with a bounded number of set-based queries
    // instead of one query per row per relation (which was O(rows × relations)
    // round trips and dominated page-load time on remote databases).
    const [forwardMaps, reverseMaps] = await Promise.all([
      Promise.all(
        foreignKeyColumns.map(async (column) => {
          const values = Array.from(
            new Set(
              dataResult.rows
                .map((r) => r[column.columnName])
                .filter((v) => v !== null && v !== undefined)
            )
          );
          const map = await this.batchLookupByColumn(
            column.references!.schema,
            column.references!.table,
            column.references!.column,
            values
          );
          return { column, map };
        })
      ),
      Promise.all(
        reverseRelations.map(async (rr) => {
          const values = Array.from(
            new Set(
              dataResult.rows
                .map((r) => r[rr.referencedColumn])
                .filter((v) => v !== null && v !== undefined)
            )
          );
          const counts = await this.batchCountByColumn(
            rr.referencingSchema,
            rr.referencingTable,
            rr.referencingColumn,
            values
          );
          return { rr, counts };
        })
      ),
    ]);

    const enhancedData = dataResult.rows.map((row) => {
      const relations: { [columnName: string]: any } = {};
      const reverseRelationsData: { [relationKey: string]: any } = {};

      for (const { column, map } of forwardMaps) {
        const value = row[column.columnName];
        if (value === null || value === undefined) continue;
        const relatedRecords = map.get(String(value));
        if (!relatedRecords || !relatedRecords.length) continue;
        relations[column.columnName] = {
          columnName: column.columnName,
          referencedTable: column.references!.table,
          referencedColumn: column.references!.column,
          referencedSchema: column.references!.schema,
          relatedRecords,
        };
      }

      for (const { rr, counts } of reverseMaps) {
        const recordId = row[rr.referencedColumn];
        if (recordId === null || recordId === undefined) continue;
        const relationKey = `${rr.referencingSchema}.${rr.referencingTable}.${rr.referencingColumn}`;
        reverseRelationsData[relationKey] = {
          referencingTable: rr.referencingTable,
          referencingSchema: rr.referencingSchema,
          referencingColumn: rr.referencingColumn,
          relationCount: counts.get(String(recordId)) ?? 0,
        };
      }

      return {
        ...row,
        _relations: relations,
        _reverseRelations: reverseRelationsData,
      };
    });

    return {
      data: enhancedData,
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
   * Fetch all rows whose `column` matches any of `values`, grouped by value.
   * One query for the whole page instead of one per row.
   */
  private async batchLookupByColumn(
    schemaName: string,
    tableName: string,
    columnName: string,
    values: any[]
  ): Promise<Map<string, any[]>> {
    const grouped = new Map<string, any[]>();
    if (!values.length) return grouped;

    const qualified = this.getQualifiedTableName(schemaName, tableName);
    const quotedColumn = this.quoteIdentifier(columnName);

    try {
      const result = await this.databaseService.query(
        `SELECT * FROM ${qualified} WHERE ${quotedColumn} = ANY($1)`,
        [values]
      );
      for (const row of result.rows) {
        const key = String(row[columnName]);
        const bucket = grouped.get(key);
        if (bucket) bucket.push(row);
        else grouped.set(key, [row]);
      }
    } catch (error) {
      console.warn(
        `[DataManagement] Batch relation lookup failed for ${schemaName}.${tableName}.${columnName}:`,
        error.message
      );
    }
    return grouped;
  }

  /**
   * Count referencing rows per key value in a single grouped query.
   */
  private async batchCountByColumn(
    schemaName: string,
    tableName: string,
    columnName: string,
    values: any[]
  ): Promise<Map<string, number>> {
    const counts = new Map<string, number>();
    if (!values.length) return counts;

    const qualified = this.getQualifiedTableName(schemaName, tableName);
    const quotedColumn = this.quoteIdentifier(columnName);

    try {
      const result = await this.databaseService.query(
        `SELECT ${quotedColumn} AS key, COUNT(*)::bigint AS total
         FROM ${qualified}
         WHERE ${quotedColumn} = ANY($1)
         GROUP BY ${quotedColumn}`,
        [values]
      );
      for (const row of result.rows) {
        counts.set(String(row.key), parseInt(row.total) || 0);
      }
    } catch (error) {
      console.warn(
        `[DataManagement] Batch relation count failed for ${schemaName}.${tableName}.${columnName}:`,
        error.message
      );
    }
    return counts;
  }

  /**
   * Get reverse relations for a table (tables that reference this table)
   */
  async getReverseRelations(
    schemaName: string,
    tableName: string
  ): Promise<
    Array<{
      referencingTable: string;
      referencingSchema: string;
      referencingColumn: string;
      referencedColumn: string;
    }>
  > {
    // pg_catalog with ordinal-matched key columns: joining information_schema
    // on constraint_name alone cross-produces the columns of composite foreign
    // keys and can collide across schemas.
    const query = `
      SELECT DISTINCT
        cns.nspname AS referencing_schema,
        cc.relname  AS referencing_table,
        ca.attname  AS referencing_column,
        ra.attname  AS referenced_column
      FROM pg_constraint con
      JOIN pg_class cc      ON cc.oid = con.conrelid
      JOIN pg_namespace cns ON cns.oid = cc.relnamespace
      JOIN pg_class rc      ON rc.oid = con.confrelid
      JOIN pg_namespace rns ON rns.oid = rc.relnamespace
      JOIN LATERAL unnest(con.conkey, con.confkey)
        WITH ORDINALITY AS u(att, refatt, ord) ON true
      JOIN pg_attribute ca ON ca.attrelid = con.conrelid AND ca.attnum = u.att
      JOIN pg_attribute ra ON ra.attrelid = con.confrelid AND ra.attnum = u.refatt
      WHERE con.contype = 'f'
        AND rns.nspname = $1
        AND rc.relname = $2
      ORDER BY 1, 2, 3;
    `;

    const result = await this.databaseService.query(query, [
      schemaName,
      tableName,
    ]);

    return result.rows.map((row) => ({
      referencingTable: String(row.referencing_table || ""),
      referencingSchema: String(row.referencing_schema || ""),
      referencingColumn: String(row.referencing_column || ""),
      referencedColumn: String(row.referenced_column || ""),
    }));
  }

  /**
   * Get reverse relation data for a specific record
   */
  async getReverseRelationData(
    schemaName: string,
    tableName: string,
    recordId: any,
    referencedColumn: string,
    referencingSchema: string,
    referencingTable: string,
    referencingColumn: string,
    queryOptions: TableQueryDto = {}
  ): Promise<{
    data: any[];
    totalCount: number;
  }> {
    const { limit = 10, page = 1 } = queryOptions;
    const offset = (page - 1) * limit;

    const referencingQualifiedTable = this.getQualifiedTableName(
      referencingSchema,
      referencingTable
    );
    const quotedReferencingColumn = this.quoteIdentifier(referencingColumn);

    // Get total count
    const countQuery = `
      SELECT COUNT(*) as total 
      FROM ${referencingQualifiedTable} 
      WHERE ${quotedReferencingColumn} = $1
    `;
    const countResult = await this.databaseService.query(countQuery, [
      recordId,
    ]);
    const totalCount = parseInt(countResult.rows[0].total);

    // Get data
    const dataQuery = `
      SELECT * 
      FROM ${referencingQualifiedTable} 
      WHERE ${quotedReferencingColumn} = $1
      ORDER BY ${quotedReferencingColumn}
      LIMIT $2 OFFSET $3
    `;
    const dataResult = await this.databaseService.query(dataQuery, [
      recordId,
      limit,
      offset,
    ]);

    return {
      data: dataResult.rows,
      totalCount,
    };
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
      const conditions = filters.map((filter) => {
        const paramIndex = queryParams.length + 1;
        queryParams.push(this.formatFilterValue(filter));
        return `${this.quoteIdentifier(filter.column)} ${this.safeOperator(filter.operator)} $${paramIndex}`;
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
    // Primary/foreign keys are resolved through pg_catalog rather than
    // information_schema. The information_schema joins matched constraints by
    // name only, which duplicated columns that belong to more than one
    // constraint (e.g. a composite PK column that is also a FK) and flagged
    // UNIQUE columns as primary keys.
    const query = `
      WITH rel AS (
        SELECT c.oid
        FROM pg_class c
        JOIN pg_namespace n ON n.oid = c.relnamespace
        WHERE n.nspname = $1 AND c.relname = $2
      ),
      pk AS (
        SELECT a.attname
        FROM pg_constraint con
        JOIN rel ON rel.oid = con.conrelid
        JOIN pg_attribute a
          ON a.attrelid = con.conrelid AND a.attnum = ANY(con.conkey)
        WHERE con.contype = 'p'
      ),
      fk AS (
        SELECT DISTINCT ON (a.attname)
          a.attname            AS column_name,
          fns.nspname          AS foreign_table_schema,
          fc.relname           AS foreign_table_name,
          fa.attname           AS foreign_column_name
        FROM pg_constraint con
        JOIN rel ON rel.oid = con.conrelid
        JOIN LATERAL unnest(con.conkey, con.confkey)
          WITH ORDINALITY AS u(att, refatt, ord) ON true
        JOIN pg_attribute a   ON a.attrelid = con.conrelid AND a.attnum = u.att
        JOIN pg_class fc      ON fc.oid = con.confrelid
        JOIN pg_namespace fns ON fns.oid = fc.relnamespace
        JOIN pg_attribute fa  ON fa.attrelid = con.confrelid AND fa.attnum = u.refatt
        WHERE con.contype = 'f'
        ORDER BY a.attname, con.oid
      )
      SELECT
        c.column_name,
        c.data_type,
        c.is_nullable,
        c.column_default,
        c.character_maximum_length,
        c.numeric_precision,
        c.numeric_scale,
        c.is_identity,
        (pk.attname IS NOT NULL)     AS is_primary_key,
        (fk.column_name IS NOT NULL) AS is_foreign_key,
        fk.foreign_table_schema,
        fk.foreign_table_name,
        fk.foreign_column_name
      FROM information_schema.columns c
      LEFT JOIN pk ON pk.attname = c.column_name
      LEFT JOIN fk ON fk.column_name = c.column_name
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
        con.conname          AS constraint_name,
        ca.attname           AS column_name,
        fns.nspname          AS foreign_table_schema,
        fc.relname           AS foreign_table_name,
        fa.attname           AS foreign_column_name
      FROM pg_constraint con
      JOIN pg_class c       ON c.oid = con.conrelid
      JOIN pg_namespace n   ON n.oid = c.relnamespace
      JOIN pg_class fc      ON fc.oid = con.confrelid
      JOIN pg_namespace fns ON fns.oid = fc.relnamespace
      JOIN LATERAL unnest(con.conkey, con.confkey)
        WITH ORDINALITY AS u(att, refatt, ord) ON true
      JOIN pg_attribute ca ON ca.attrelid = con.conrelid AND ca.attnum = u.att
      JOIN pg_attribute fa ON fa.attrelid = con.confrelid AND fa.attnum = u.refatt
      WHERE con.contype = 'f'
        AND n.nspname = $1
        AND c.relname = $2
      ORDER BY con.conname, u.ord;
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
    // Resolved via pg_index so that primary keys are identified by
    // indisprimary (not a "%_pkey" name heuristic) and indexes are scoped to
    // the requested schema (the old pg_class join matched on relname alone,
    // so same-named tables in other schemas produced duplicates).
    const query = `
      SELECT
        ic.relname                                   AS index_name,
        ix.indisunique                               AS is_unique,
        ix.indisprimary                              AS is_primary,
        ARRAY(
          SELECT pg_get_indexdef(ix.indexrelid, k.ord::int, true)
          FROM unnest(ix.indkey) WITH ORDINALITY AS k(attnum, ord)
          ORDER BY k.ord
        )                                            AS columns
      FROM pg_index ix
      JOIN pg_class tc  ON tc.oid = ix.indrelid
      JOIN pg_class ic  ON ic.oid = ix.indexrelid
      JOIN pg_namespace n ON n.oid = tc.relnamespace
      WHERE n.nspname = $1 AND tc.relname = $2
      ORDER BY ix.indisprimary DESC, ic.relname;
    `;

    const result = await this.databaseService.query(query, [
      schemaName,
      tableName,
    ]);

    return result.rows.map((row) => ({
      indexName: row.index_name,
      columns: (row.columns || []).filter((c: string) => c && c.length > 0),
      isUnique: row.is_unique,
      isPrimary: row.is_primary,
    }));
  }

  private async getTableRowCount(
    schemaName: string,
    tableName: string
  ): Promise<number> {
    // Exact count for the single table being inspected. (The previous
    // implementation summed n_tup_ins + n_tup_upd + n_tup_del, which is
    // cumulative write activity, not a row count.)
    const qualified = this.getQualifiedTableName(schemaName, tableName);
    try {
      const result = await this.databaseService.query(
        `SELECT COUNT(*)::bigint AS exact_rows FROM ${qualified}`
      );
      return parseInt(result.rows[0].exact_rows) || 0;
    } catch {
      // Fall back to the planner estimate if the exact count fails
      // (permissions, very large table with a statement timeout, ...).
      const est = await this.databaseService.query(
        `SELECT GREATEST(c.reltuples, 0)::bigint AS estimated_rows
         FROM pg_class c
         JOIN pg_namespace n ON n.oid = c.relnamespace
         WHERE n.nspname = $1 AND c.relname = $2`,
        [schemaName, tableName]
      );
      return est.rows.length ? parseInt(est.rows[0].estimated_rows) || 0 : 0;
    }
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
    // Strip line and block comments so they can't hide a write statement.
    const sanitized = query
      .replace(/--[^\n]*/g, " ")
      .replace(/\/\*[\s\S]*?\*\//g, " ");

    // Word-boundary match so common column names like created_at, updated_at
    // and deleted_at are NOT mistaken for CREATE/UPDATE/DELETE.
    const writePattern =
      /\b(INSERT|UPDATE|DELETE|DROP|CREATE|ALTER|TRUNCATE|GRANT|REVOKE|MERGE|COPY|CALL|DO|VACUUM|REINDEX|REFRESH)\b/i;
    return writePattern.test(sanitized);
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
