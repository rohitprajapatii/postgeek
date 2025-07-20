import {
  Controller,
  Get,
  Post,
  Put,
  Delete,
  Body,
  Param,
  Query,
  HttpException,
  HttpStatus,
  ValidationPipe,
  Header,
  BadRequestException,
} from "@nestjs/common";
import { DataManagementService } from "./data-management.service";
import {
  TableQueryDto,
  CreateRecordDto,
  UpdateRecordDto,
  DeleteRecordDto,
  BulkOperationDto,
  QueryExecutionDto,
  FilterCondition,
} from "./dto/table-query.dto";

@Controller("data-management")
export class DataManagementController {
  constructor(private readonly dataManagementService: DataManagementService) {}

  /**
   * Get all schemas and tables
   */
  @Get("schemas")
  async getSchemas() {
    console.log("[DataManagementController] GET /data-management/schemas");
    try {
      const schemas = await this.dataManagementService.getSchemas();
      console.log(`[DataManagementController] Found ${schemas.length} schemas`);
      return {
        success: true,
        data: schemas,
      };
    } catch (error) {
      console.error(
        "[DataManagementController] Error fetching schemas:",
        error
      );

      // Check if it's a database connection error
      if (
        error instanceof HttpException &&
        error.getStatus() === HttpStatus.BAD_REQUEST
      ) {
        throw error; // Re-throw with original status (400)
      }

      throw new HttpException(
        "Failed to fetch schemas",
        HttpStatus.INTERNAL_SERVER_ERROR
      );
    }
  }

  /**
   * Get table information including structure and metadata
   */
  @Get("tables/:schema/:table/info")
  async getTableInfo(
    @Param("schema") schema: string,
    @Param("table") table: string
  ) {
    console.log(
      `[DataManagementController] GET /data-management/tables/${schema}/${table}/info`
    );
    try {
      const tableInfo = await this.dataManagementService.getTableInfo(
        schema,
        table
      );
      return {
        success: true,
        data: tableInfo,
      };
    } catch (error) {
      console.error(
        "[DataManagementController] Error fetching table info:",
        error
      );
      throw new HttpException(
        "Failed to fetch table information",
        HttpStatus.INTERNAL_SERVER_ERROR
      );
    }
  }

  /**
   * Get table data with pagination, sorting, and filtering
   */
  @Get("tables/:schema/:table/data")
  async getTableData(
    @Param("schema") schema: string,
    @Param("table") table: string,
    @Query() queryOptions: TableQueryDto
  ) {
    console.log(
      `[DataManagementController] GET /data-management/tables/${schema}/${table}/data`
    );
    console.log("[DataManagementController] Query options:", queryOptions);

    try {
      const result = await this.dataManagementService.getTableData(
        schema,
        table,
        queryOptions
      );
      return {
        success: true,
        data: result.data,
        pagination: result.pagination,
      };
    } catch (error) {
      console.error(
        "[DataManagementController] Error fetching table data:",
        error
      );
      throw new HttpException(
        "Failed to fetch table data",
        HttpStatus.INTERNAL_SERVER_ERROR
      );
    }
  }

  /**
   * Create a new record
   */
  @Post("tables/:schema/:table/records")
  async createRecord(
    @Param("schema") schema: string,
    @Param("table") table: string,
    @Body(ValidationPipe) createDto: CreateRecordDto
  ) {
    console.log(
      `[DataManagementController] POST /data-management/tables/${schema}/${table}/records`
    );

    try {
      const result = await this.dataManagementService.createRecord(
        schema,
        table,
        createDto
      );
      return {
        success: true,
        data: result,
        message: "Record created successfully",
      };
    } catch (error) {
      console.error("[DataManagementController] Error creating record:", error);
      throw new HttpException(
        `Failed to create record: ${error.message}`,
        HttpStatus.BAD_REQUEST
      );
    }
  }

  /**
   * Update records
   */
  @Put("tables/:schema/:table/records")
  async updateRecord(
    @Param("schema") schema: string,
    @Param("table") table: string,
    @Body(ValidationPipe) updateDto: UpdateRecordDto
  ) {
    console.log(
      `[DataManagementController] PUT /data-management/tables/${schema}/${table}/records`
    );

    try {
      const result = await this.dataManagementService.updateRecord(
        schema,
        table,
        updateDto
      );
      return {
        success: true,
        data: result,
        message: `Updated ${result.length} record(s)`,
      };
    } catch (error) {
      console.error("[DataManagementController] Error updating record:", error);
      throw new HttpException(
        `Failed to update record: ${error.message}`,
        HttpStatus.BAD_REQUEST
      );
    }
  }

  /**
   * Delete records
   */
  @Delete("tables/:schema/:table/records")
  async deleteRecord(
    @Param("schema") schema: string,
    @Param("table") table: string,
    @Body(ValidationPipe) deleteDto: DeleteRecordDto
  ) {
    console.log(
      `[DataManagementController] DELETE /data-management/tables/${schema}/${table}/records`
    );

    try {
      const deletedCount = await this.dataManagementService.deleteRecord(
        schema,
        table,
        deleteDto
      );
      return {
        success: true,
        data: { deletedCount },
        message: `Deleted ${deletedCount} record(s)`,
      };
    } catch (error) {
      console.error("[DataManagementController] Error deleting record:", error);
      throw new HttpException(
        `Failed to delete record: ${error.message}`,
        HttpStatus.BAD_REQUEST
      );
    }
  }

  /**
   * Bulk insert records
   */
  @Post("tables/:schema/:table/bulk-insert")
  async bulkInsert(
    @Param("schema") schema: string,
    @Param("table") table: string,
    @Body(ValidationPipe) bulkDto: BulkOperationDto
  ) {
    console.log(
      `[DataManagementController] POST /data-management/tables/${schema}/${table}/bulk-insert`
    );

    try {
      const result = await this.dataManagementService.bulkInsert(
        schema,
        table,
        bulkDto
      );
      return {
        success: result.success,
        data: result,
        message: `Processed ${result.processedCount} record(s)`,
      };
    } catch (error) {
      console.error(
        "[DataManagementController] Error with bulk insert:",
        error
      );
      throw new HttpException(
        `Failed to bulk insert: ${error.message}`,
        HttpStatus.BAD_REQUEST
      );
    }
  }

  /**
   * Execute custom SQL query
   */
  @Post("query/execute")
  async executeQuery(@Body(ValidationPipe) queryDto: QueryExecutionDto) {
    console.log(
      "[DataManagementController] POST /data-management/query/execute"
    );
    console.log(
      "[DataManagementController] Query type:",
      queryDto.readonly ? "readonly" : "write"
    );

    try {
      const result = await this.dataManagementService.executeQuery(queryDto);
      return {
        success: true,
        data: result,
        message: `Query executed in ${result.executionTime}ms`,
      };
    } catch (error) {
      console.error("[DataManagementController] Error executing query:", error);
      throw new HttpException(
        `Query execution failed: ${error.message}`,
        HttpStatus.BAD_REQUEST
      );
    }
  }

  /**
   * Get foreign key referenced data
   */
  @Get("foreign-key-data/:schema/:table/:column")
  async getForeignKeyData(
    @Param("schema") schema: string,
    @Param("table") table: string,
    @Param("column") column: string,
    @Query("value") value: string
  ) {
    console.log(
      `[DataManagementController] GET /data-management/foreign-key-data/${schema}/${table}/${column}`
    );

    try {
      const result = await this.dataManagementService.getForeignKeyData(
        schema,
        table,
        column,
        value
      );
      return {
        success: true,
        data: result,
      };
    } catch (error) {
      console.error(
        "[DataManagementController] Error fetching foreign key data:",
        error
      );
      throw new HttpException(
        "Failed to fetch foreign key data",
        HttpStatus.INTERNAL_SERVER_ERROR
      );
    }
  }

  /**
   * Export table data
   */
  @Post("tables/:schema/:table/export")
  @Header("Content-Type", "application/octet-stream")
  async exportTableData(
    @Param("schema") schema: string,
    @Param("table") table: string,
    @Body()
    exportOptions: {
      format?: "csv" | "json";
      filters?: FilterCondition[];
    }
  ) {
    console.log(
      `[DataManagementController] POST /data-management/tables/${schema}/${table}/export`
    );

    try {
      const { format = "csv", filters } = exportOptions;
      const result = await this.dataManagementService.exportTableData(
        schema,
        table,
        format,
        filters
      );

      return {
        success: true,
        data: result,
        filename: `${schema}_${table}.${format}`,
      };
    } catch (error) {
      console.error("[DataManagementController] Error exporting data:", error);
      throw new HttpException(
        "Failed to export table data",
        HttpStatus.INTERNAL_SERVER_ERROR
      );
    }
  }

  /**
   * Search tables across all schemas
   */
  @Get("search/tables")
  async searchTables(@Query("q") searchQuery: string) {
    console.log(
      `[DataManagementController] GET /data-management/search/tables?q=${searchQuery}`
    );

    try {
      const schemas = await this.dataManagementService.getSchemas();
      const results = [];

      for (const schema of schemas) {
        for (const table of schema.tables) {
          if (
            table.tableName.toLowerCase().includes(searchQuery.toLowerCase()) ||
            schema.schemaName.toLowerCase().includes(searchQuery.toLowerCase())
          ) {
            results.push({
              schemaName: schema.schemaName,
              tableName: table.tableName,
              rowCount: table.rowCount,
            });
          }
        }
      }

      return {
        success: true,
        data: results,
        total: results.length,
      };
    } catch (error) {
      console.error(
        "[DataManagementController] Error searching tables:",
        error
      );
      throw new HttpException(
        "Failed to search tables",
        HttpStatus.INTERNAL_SERVER_ERROR
      );
    }
  }

  /**
   * Get table statistics
   */
  @Get("tables/:schema/:table/statistics")
  async getTableStatistics(
    @Param("schema") schema: string,
    @Param("table") table: string
  ) {
    console.log(
      `[DataManagementController] GET /data-management/tables/${schema}/${table}/statistics`
    );

    try {
      const tableInfo = await this.dataManagementService.getTableInfo(
        schema,
        table
      );

      // Get column statistics
      const columnStats = await Promise.all(
        tableInfo.columns.map(async (column) => {
          try {
            const statsQuery = `
              SELECT 
                COUNT(*) as total_count,
                COUNT(${column.columnName}) as non_null_count,
                COUNT(*) - COUNT(${column.columnName}) as null_count
              FROM ${schema}.${table}
            `;
            const result = await this.dataManagementService.executeQuery({
              query: statsQuery,
              readonly: true,
            });

            return {
              columnName: column.columnName,
              dataType: column.dataType,
              totalCount: parseInt(result.rows[0]?.total_count || "0"),
              nonNullCount: parseInt(result.rows[0]?.non_null_count || "0"),
              nullCount: parseInt(result.rows[0]?.null_count || "0"),
              nullPercentage: result.rows[0]?.total_count
                ? (
                    (parseInt(result.rows[0].null_count) /
                      parseInt(result.rows[0].total_count)) *
                    100
                  ).toFixed(2)
                : "0",
            };
          } catch (error) {
            return {
              columnName: column.columnName,
              dataType: column.dataType,
              error: "Could not retrieve statistics",
            };
          }
        })
      );

      return {
        success: true,
        data: {
          tableInfo,
          columnStatistics: columnStats,
        },
      };
    } catch (error) {
      console.error(
        "[DataManagementController] Error fetching table statistics:",
        error
      );
      throw new HttpException(
        "Failed to fetch table statistics",
        HttpStatus.INTERNAL_SERVER_ERROR
      );
    }
  }

  /**
   * Get related table data for a foreign key relation
   */
  @Get("tables/:schema/:table/relations/:column/:value")
  async getRelatedTableData(
    @Param("schema") schema: string,
    @Param("table") table: string,
    @Param("column") column: string,
    @Param("value") value: string,
    @Query() queryOptions: TableQueryDto
  ) {
    console.log(
      `[DataManagementController] GET /data-management/tables/${schema}/${table}/relations/${column}/${value}`
    );

    try {
      // Get table info to find the foreign key reference
      const tableInfo = await this.dataManagementService.getTableInfo(
        schema,
        table
      );

      const foreignKeyColumn = tableInfo.columns.find(
        (col) => col.columnName === column && col.isForeignKey && col.references
      );

      if (!foreignKeyColumn || !foreignKeyColumn.references) {
        throw new HttpException(
          `Column ${column} is not a foreign key`,
          HttpStatus.BAD_REQUEST
        );
      }

      // Get the related table data
      const relatedTableData = await this.dataManagementService.getTableData(
        foreignKeyColumn.references.schema,
        foreignKeyColumn.references.table,
        {
          ...queryOptions,
          filters: [
            {
              column: foreignKeyColumn.references.column,
              operator: "=",
              value: value,
            },
          ],
        }
      );

      return {
        success: true,
        data: relatedTableData.data,
        pagination: relatedTableData.pagination,
        relationInfo: {
          sourceSchema: schema,
          sourceTable: table,
          sourceColumn: column,
          targetSchema: foreignKeyColumn.references.schema,
          targetTable: foreignKeyColumn.references.table,
          targetColumn: foreignKeyColumn.references.column,
        },
      };
    } catch (error) {
      console.error(
        "[DataManagementController] Error fetching related table data:",
        error
      );
      throw new HttpException(
        "Failed to fetch related table data",
        HttpStatus.INTERNAL_SERVER_ERROR
      );
    }
  }

  /**
   * Get reverse relation data for a specific record
   */
  @Get("tables/:schema/:table/reverse-relations/:referencedColumn/:recordId")
  async getReverseRelationData(
    @Param("schema") schema: string,
    @Param("table") table: string,
    @Param("referencedColumn") referencedColumn: string,
    @Param("recordId") recordId: string,
    @Query("referencingSchema") referencingSchema: string,
    @Query("referencingTable") referencingTable: string,
    @Query("referencingColumn") referencingColumn: string,
    @Query("limit") limit: string = "50",
    @Query("page") page: string = "1",
    @Query("sortBy") sortBy?: string,
    @Query("sortOrder") sortOrder?: string
  ) {
    // Create queryOptions object from individual parameters
    const queryOptions: TableQueryDto = {
      limit: parseInt(limit, 10) || 50,
      page: parseInt(page, 10) || 1,
      sortBy: sortBy,
      sortOrder: (sortOrder as "ASC" | "DESC") || "ASC",
    };

    try {
      // Validate required parameters
      if (!schema || !table || !referencedColumn || !recordId) {
        throw new BadRequestException("Missing required path parameters");
      }

      if (!referencingSchema || !referencingTable || !referencingColumn) {
        throw new BadRequestException("Missing required query parameters");
      }

      const result = await this.dataManagementService.getReverseRelationData(
        schema,
        table,
        recordId,
        referencedColumn,
        referencingSchema,
        referencingTable,
        referencingColumn,
        queryOptions
      );

      return result;
    } catch (error) {
      throw error;
    }
  }

  /**
   * Test endpoint to verify reverse relation route is accessible
   */
  @Get("test/reverse-relation-route")
  async testReverseRelationRoute() {
    return {
      message: "Reverse relation route is accessible",
      timestamp: new Date(),
    };
  }
}
