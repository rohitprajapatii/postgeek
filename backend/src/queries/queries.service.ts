import { Injectable } from "@nestjs/common";
import { DatabaseService } from "../database/database.service";

@Injectable()
export class QueriesService {
  constructor(private readonly databaseService: DatabaseService) {}

  private async checkPgStatStatements(): Promise<boolean> {
    try {
      const checkExtension = await this.databaseService.query(
        "SELECT EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_stat_statements')"
      );
      return checkExtension.rows[0].exists;
    } catch (error) {
      console.error("Error checking pg_stat_statements extension:", error);
      return false;
    }
  }

  private async getAvailableColumns(): Promise<string[]> {
    try {
      const result = await this.databaseService.query(`
        SELECT column_name 
        FROM information_schema.columns 
        WHERE table_name = 'pg_stat_statements' 
          AND table_schema = 'public'
        ORDER BY ordinal_position;
      `);
      return result.rows.map((row) => row.column_name);
    } catch (error) {
      console.error("Error getting available columns:", error);
      // Return basic columns that should be available in all versions
      return [
        "queryid",
        "query",
        "calls",
        "total_exec_time",
        "mean_exec_time",
        "min_exec_time",
        "max_exec_time",
        "stddev_exec_time",
        "rows",
        "shared_blks_hit",
        "shared_blks_read",
        "shared_blks_dirtied",
        "shared_blks_written",
      ];
    }
  }

  async getSlowQueries(limit: number = 10) {
    try {
      const hasExtension = await this.checkPgStatStatements();

      if (!hasExtension) {
        return {
          error: "pg_stat_statements extension is not installed",
          hint: "Run CREATE EXTENSION pg_stat_statements; as a superuser",
          fallback:
            "Consider enabling query logging in postgresql.conf for manual analysis",
        };
      }

      // Use only the core columns that are available in all versions
      const slowQueriesQuery = `
        SELECT
          queryid,
          query,
          calls,
          total_exec_time as total_time_ms,
          mean_exec_time as avg_time_ms,
          min_exec_time as min_time_ms,
          max_exec_time as max_time_ms,
          stddev_exec_time as stddev_time_ms,
          rows,
          shared_blks_hit,
          shared_blks_read,
          shared_blks_dirtied,
          shared_blks_written,
          local_blks_hit,
          local_blks_read,
          local_blks_dirtied,
          local_blks_written,
          temp_blks_read,
          temp_blks_written
        FROM pg_stat_statements
        WHERE query !~ '^[[:space:]]*(BEGIN|COMMIT|ROLLBACK|SET|SHOW|EXPLAIN)'
          AND query !~ 'pg_stat_statements'
        ORDER BY total_exec_time DESC
        LIMIT $1;
      `;

      const result = await this.databaseService.query(slowQueriesQuery, [
        limit,
      ]);
      return result.rows;
    } catch (error) {
      console.error("Error retrieving slow queries:", error);
      return { error: error.message };
    }
  }

  async getQueryStats() {
    try {
      const hasExtension = await this.checkPgStatStatements();

      if (!hasExtension) {
        // Return basic database stats as fallback
        const fallbackQuery = `
          SELECT
            (SELECT count(*) FROM pg_stat_activity WHERE state = 'active') as active_connections,
            (SELECT count(*) FROM pg_stat_activity) as total_connections,
            (SELECT datname FROM pg_database WHERE datname = current_database()) as database_name,
            (SELECT version()) as postgres_version;
        `;

        const result = await this.databaseService.query(fallbackQuery);
        return {
          ...result.rows[0],
          message:
            "pg_stat_statements extension not available - showing basic stats",
          hint: "Enable pg_stat_statements for detailed query performance metrics",
        };
      }

      const statsQuery = `
        SELECT
          SUM(calls) as total_calls,
          SUM(total_exec_time) as total_exec_time_ms,
          SUM(total_exec_time) / SUM(calls) as avg_query_time_ms,
          SUM(rows) as total_rows,
          SUM(shared_blks_hit) as shared_blocks_hit,
          SUM(shared_blks_read) as shared_blocks_read,
          CASE WHEN (SUM(shared_blks_hit) + SUM(shared_blks_read)) > 0
            THEN ROUND(SUM(shared_blks_hit)::numeric / (SUM(shared_blks_hit) + SUM(shared_blks_read))::numeric * 100, 2)
            ELSE 0
          END as cache_hit_ratio
        FROM pg_stat_statements
        WHERE query !~ '^[[:space:]]*(BEGIN|COMMIT|ROLLBACK|SET|SHOW|EXPLAIN)'
          AND query !~ 'pg_stat_statements';
      `;

      const result = await this.databaseService.query(statsQuery);
      return result.rows[0];
    } catch (error) {
      console.error("Error retrieving query stats:", error);
      return { error: error.message };
    }
  }

  async getQueryTypes() {
    try {
      const hasExtension = await this.checkPgStatStatements();

      if (!hasExtension) {
        // Return mock data structure for frontend compatibility
        return [
          {
            query_type: "SELECT",
            count: 0,
            total_calls: 0,
            total_time_ms: 0,
            avg_time_ms: 0,
            total_rows: 0,
            message: "pg_stat_statements extension not available",
            hint: "Enable pg_stat_statements for query type analysis",
          },
        ];
      }

      const queryTypesQuery = `
        SELECT
          CASE 
            WHEN query LIKE 'SELECT%' THEN 'SELECT'
            WHEN query LIKE 'INSERT%' THEN 'INSERT'
            WHEN query LIKE 'UPDATE%' THEN 'UPDATE'
            WHEN query LIKE 'DELETE%' THEN 'DELETE'
            ELSE 'OTHER'
          END as query_type,
          COUNT(*) as count,
          SUM(calls) as total_calls,
          SUM(total_exec_time) as total_time_ms,
          AVG(mean_exec_time) as avg_time_ms,
          SUM(rows) as total_rows
        FROM pg_stat_statements
        WHERE query !~ '^[[:space:]]*(BEGIN|COMMIT|ROLLBACK|SET|SHOW|EXPLAIN)'
          AND query !~ 'pg_stat_statements'
        GROUP BY query_type
        ORDER BY total_time_ms DESC;
      `;

      const result = await this.databaseService.query(queryTypesQuery);
      return result.rows;
    } catch (error) {
      console.error("Error retrieving query types:", error);
      return { error: error.message };
    }
  }

  async resetQueryStats() {
    try {
      const hasExtension = await this.checkPgStatStatements();

      if (!hasExtension) {
        return {
          error: "pg_stat_statements extension is not installed",
          hint: "Run CREATE EXTENSION pg_stat_statements; as a superuser",
        };
      }

      await this.databaseService.query("SELECT pg_stat_statements_reset()");
      return { success: true, message: "Query statistics have been reset" };
    } catch (error) {
      console.error("Error resetting query stats:", error);
      return { error: error.message };
    }
  }
}
