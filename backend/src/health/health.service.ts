import { Injectable } from "@nestjs/common";
import { DatabaseService } from "../database/database.service";

@Injectable()
export class HealthService {
  constructor(private readonly databaseService: DatabaseService) {}

  async getHealthOverview() {
    // Check database connection
    const connectionStatus = this.databaseService.getConnectionStatus();
    if (!connectionStatus.isConnected) {
      return { connected: false };
    }

    // Each metric is resolved independently: managed databases frequently
    // restrict access to individual catalog views (pg_stat_replication is a
    // common one), and a single failure must not blank out the whole page.
    const [
      vacuumStatus,
      connectionCount,
      deadlocks,
      cacheHitRatio,
      dbSize,
      replicationStatus,
    ] = await Promise.all([
      this.safeMetric("vacuum_status", () => this.getVacuumStatus(), []),
      this.safeMetric("connection_count", () => this.getConnectionCount(), null),
      this.safeMetric("deadlocks", () => this.getDeadlocks(), null),
      this.safeMetric("cache_hit_ratio", () => this.getCacheHitRatio(), null),
      this.safeMetric("database_size", () => this.getDatabaseSize(), null),
      this.safeMetric("replication", () => this.getReplicationStatus(), []),
    ]);

    return {
      connected: true,
      vacuum_status: vacuumStatus,
      connection_count: connectionCount,
      deadlocks,
      cache_hit_ratio: cacheHitRatio,
      database_size: dbSize,
      replication: replicationStatus,
    };
  }

  /**
   * Run a single health metric, degrading to a fallback (and an inline error
   * marker) instead of rejecting the whole overview.
   */
  private async safeMetric<T>(
    name: string,
    fn: () => Promise<T>,
    fallback: T
  ): Promise<T | { error: string }> {
    try {
      return await fn();
    } catch (error) {
      console.warn(`[HealthService] Metric "${name}" unavailable:`, error.message);
      return fallback === null ? { error: error.message } : fallback;
    }
  }

  private async getVacuumStatus() {
    const vacuumQuery = `
      SELECT
        schemaname as schema,
        relname as table_name,
        n_dead_tup as dead_tuples,
        n_live_tup as live_tuples,
        CASE
          WHEN n_live_tup = 0 THEN 100
          ELSE ROUND(n_dead_tup::numeric / n_live_tup::numeric * 100, 2)
        END as dead_tuples_ratio,
        last_vacuum,
        last_autovacuum,
        last_analyze,
        last_autoanalyze,
        vacuum_count,
        autovacuum_count
      FROM pg_stat_user_tables
      WHERE n_dead_tup > 0
      ORDER BY n_dead_tup DESC
      LIMIT 10;
    `;

    const result = await this.databaseService.query(vacuumQuery);
    return result.rows;
  }

  private async getConnectionCount() {
    const connectionQuery = `
      SELECT
        max_conn,
        used,
        res_for_super,
        max_conn - used - res_for_super as free
      FROM
        (SELECT count(*) used FROM pg_stat_activity) t1,
        (SELECT setting::int res_for_super FROM pg_settings WHERE name = 'superuser_reserved_connections') t2,
        (SELECT setting::int max_conn FROM pg_settings WHERE name = 'max_connections') t3;
    `;

    const result = await this.databaseService.query(connectionQuery);
    return result.rows[0];
  }

  private async getDeadlocks() {
    const deadlockQuery = `
      SELECT
        deadlocks,
        EXTRACT(EPOCH FROM (now() - stats_reset)) as seconds_since_reset
      FROM pg_stat_database
      WHERE datname = current_database();
    `;

    const result = await this.databaseService.query(deadlockQuery);
    return result.rows[0];
  }

  private async getCacheHitRatio() {
    // NULLIF guards a brand-new database where no table has served a single
    // block yet (0 hits + 0 reads), which previously raised "division by zero"
    // and failed the whole health overview.
    const cacheHitQuery = `
      SELECT
        COALESCE(SUM(heap_blks_read), 0) as heap_read,
        COALESCE(SUM(heap_blks_hit), 0) as heap_hit,
        SUM(heap_blks_hit)::numeric
          / NULLIF(SUM(heap_blks_hit) + SUM(heap_blks_read), 0) as ratio
      FROM pg_statio_user_tables;
    `;

    const result = await this.databaseService.query(cacheHitQuery);
    return result.rows[0];
  }

  private async getDatabaseSize() {
    const sizeQuery = `
      SELECT
        pg_size_pretty(pg_database_size(current_database())) as pretty_size,
        pg_database_size(current_database()) as size_bytes
      FROM pg_database
      WHERE datname = current_database();
    `;

    const result = await this.databaseService.query(sizeQuery);
    return result.rows[0];
  }

  private async getReplicationStatus() {
    try {
      const replicationQuery = `
        SELECT
          client_addr as client_address,
          usename as username,
          application_name,
          state,
          sync_state,
          write_lag,
          flush_lag,
          replay_lag
        FROM pg_stat_replication;
      `;

      const result = await this.databaseService.query(replicationQuery);
      return result.rows;
    } catch (error) {
      // Replication info might not be available for all users/databases
      return { error: "Replication information not available" };
    }
  }

  async getMissingIndexes() {
    const missingIndexQuery = `
      SELECT
        schemaname as schema,
        relname as table_name,
        seq_scan as sequential_scans,
        seq_tup_read as rows_sequential_read,
        idx_scan as index_scans,
        n_live_tup as estimated_rows,
        CASE
          WHEN seq_scan > 0 THEN ROUND(seq_tup_read::numeric / seq_scan, 2)
          ELSE 0
        END as avg_rows_per_scan
      FROM pg_stat_user_tables
      WHERE seq_scan > 10
        AND (idx_scan = 0 OR seq_scan / idx_scan > 3)
        AND n_live_tup > 1000
      ORDER BY seq_scan DESC, seq_tup_read DESC
      LIMIT 10;
    `;

    const result = await this.databaseService.query(missingIndexQuery);
    return result.rows;
  }

  async getUnusedIndexes() {
    const unusedIndexQuery = `
      SELECT
        schemaname as schema,
        relname as table_name,
        indexrelname as index_name,
        pg_size_pretty(pg_relation_size(indexrelid)) as index_size,
        pg_relation_size(indexrelid) as index_size_bytes,
        idx_scan as index_scans
      FROM pg_stat_user_indexes
      WHERE idx_scan < 50
        AND pg_relation_size(indexrelid) > 1024 * 1024
      ORDER BY pg_relation_size(indexrelid) DESC
      LIMIT 10;
    `;

    const result = await this.databaseService.query(unusedIndexQuery);
    return result.rows;
  }

  async getTableBloat() {
    const tableBloatQuery = `
      WITH constants AS (
        SELECT current_setting('block_size')::numeric AS bs
      ),
      table_stats AS (
        SELECT
          t.schemaname,
          t.relname,
          t.n_live_tup,
          t.n_dead_tup,
          c.reltuples AS expected_tuples,
          CEIL((c.relpages * constants.bs) / (CASE WHEN s.avg_width = 0 THEN 1 ELSE s.avg_width END)::numeric) AS estimated_rows,
          CASE WHEN t.n_live_tup = 0 THEN 0 ELSE ROUND((t.n_dead_tup::numeric / t.n_live_tup::numeric) * 100, 2) END AS dead_tup_ratio,
          c.relpages * constants.bs AS table_size_bytes,
          pg_size_pretty(c.relpages * constants.bs) AS table_size
        FROM pg_stat_user_tables t
        JOIN pg_class c ON t.relname = c.relname AND t.schemaname = c.relnamespace::regnamespace::text
        CROSS JOIN constants
        LEFT JOIN pg_stats s ON c.relname = s.tablename AND t.schemaname = s.schemaname
      )
      SELECT 
        schemaname as schema,
        relname as table_name,
        n_live_tup as live_tuples,
        n_dead_tup as dead_tuples,
        dead_tup_ratio,
        expected_tuples,
        estimated_rows,
        CASE 
          WHEN estimated_rows = 0 THEN 0
          ELSE ROUND(((expected_tuples - estimated_rows)::numeric / expected_tuples::numeric) * 100, 2)
        END as bloat_ratio,
        table_size
      FROM table_stats
      WHERE expected_tuples > 10000
        AND estimated_rows > 0
        AND ((expected_tuples - estimated_rows)::numeric / expected_tuples::numeric) > 0.2
      ORDER BY bloat_ratio DESC
      LIMIT 10;
    `;

    try {
      const result = await this.databaseService.query(tableBloatQuery);
      return result.rows;
    } catch (error) {
      console.error("Error fetching table bloat:", error);
      return { error: "Could not calculate table bloat statistics" };
    }
  }
}
