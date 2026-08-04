import { Injectable } from "@nestjs/common";
import { DatabaseService } from "../database/database.service";

@Injectable()
export class StatisticsService {
  constructor(private readonly databaseService: DatabaseService) {}
  async getDatabaseOverview() {
    const overviewQuery = `
      SELECT
        pg_database.datname as database_name,
        pg_size_pretty(pg_database_size(pg_database.datname)) as size,
        pg_database_size(pg_database.datname) as size_bytes,
        pg_stat_database.xact_commit as commits,
        pg_stat_database.xact_rollback as rollbacks,
        pg_stat_database.blks_read as blocks_read,
        pg_stat_database.blks_hit as blocks_hit,
        CASE WHEN (pg_stat_database.blks_read + pg_stat_database.blks_hit) > 0
          THEN ROUND(pg_stat_database.blks_hit::numeric / (pg_stat_database.blks_read + pg_stat_database.blks_hit)::numeric * 100, 2)
          ELSE 0
        END as cache_hit_ratio,
        pg_stat_database.tup_returned as rows_returned,
        pg_stat_database.tup_fetched as rows_fetched,
        pg_stat_database.tup_inserted as rows_inserted,
        pg_stat_database.tup_updated as rows_updated,
        pg_stat_database.tup_deleted as rows_deleted,
        pg_stat_database.conflicts as conflicts,
        pg_stat_database.temp_files as temp_files,
        pg_size_pretty(pg_stat_database.temp_bytes) as temp_bytes,
        pg_stat_database.deadlocks as deadlocks,
        pg_stat_database.stats_reset as stats_reset
      FROM pg_database
      LEFT JOIN pg_stat_database ON pg_database.datname = pg_stat_database.datname
      WHERE pg_database.datname = current_database();
    `;

    const result = await this.databaseService.query(overviewQuery);
    return result.rows[0];
  }

  async getTableStats() {
    const tableStatsQuery = `
      SELECT
        st.schemaname as schema,
        st.relname as table_name,
        pg_size_pretty(pg_total_relation_size(c.oid)) as total_size,
        pg_total_relation_size(c.oid) as total_bytes,
        pg_size_pretty(pg_relation_size(c.oid)) as table_size,
        pg_relation_size(c.oid) as table_bytes,
        pg_size_pretty(pg_total_relation_size(c.oid) - pg_relation_size(c.oid)) as index_size,
        pg_total_relation_size(c.oid) - pg_relation_size(c.oid) as index_bytes,
        st.n_live_tup as live_rows,
        st.n_dead_tup as dead_rows,
        st.seq_scan as sequential_scans,
        st.idx_scan as index_scans,
        CASE WHEN (st.seq_scan + st.idx_scan) > 0
          THEN ROUND(st.idx_scan::numeric / (st.seq_scan + st.idx_scan)::numeric * 100, 2)
          ELSE 0
        END as index_scan_ratio,
        st.seq_tup_read as rows_sequential_read,
        st.idx_tup_fetch as rows_index_fetched,
        st.n_tup_ins as rows_inserted,
        st.n_tup_upd as rows_updated,
        st.n_tup_del as rows_deleted,
        st.n_tup_hot_upd as rows_hot_updated,
        st.vacuum_count as vacuum_count,
        st.autovacuum_count as autovacuum_count,
        st.analyze_count as analyze_count,
        st.autoanalyze_count as autoanalyze_count
      FROM pg_stat_user_tables st
      JOIN pg_class c ON st.relid = c.oid
      ORDER BY pg_total_relation_size(c.oid) DESC
      LIMIT 20;
    `;

    const result = await this.databaseService.query(tableStatsQuery);
    return result.rows;
  }

  async getIndexStats() {
    const indexStatsQuery = `
      SELECT
        schemaname as schema,
        relname as table_name,
        indexrelname as index_name,
        pg_size_pretty(pg_relation_size(indexrelid)) as index_size,
        pg_relation_size(indexrelid) as index_bytes,
        idx_scan as scans,
        idx_tup_read as tuples_read,
        idx_tup_fetch as tuples_fetched,
        CASE WHEN idx_scan > 0
          THEN ROUND(idx_tup_read::numeric / idx_scan::numeric, 2)
          ELSE 0
        END as avg_tuples_per_scan,
        idx_scan as usage_count
      FROM pg_stat_user_indexes
      ORDER BY pg_relation_size(indexrelid) DESC
      LIMIT 20;
    `;

    const result = await this.databaseService.query(indexStatsQuery);
    return result.rows;
  }

  async getIoStats() {
    const ioStatsQuery = `
      SELECT
        schemaname as schema,
        relname as table_name,
        heap_blks_read as heap_blocks_read,
        heap_blks_hit as heap_blocks_hit,
        CASE WHEN (heap_blks_read + heap_blks_hit) > 0
          THEN ROUND(heap_blks_hit::numeric / (heap_blks_read + heap_blks_hit)::numeric * 100, 2)
          ELSE 0
        END as heap_hit_ratio,
        idx_blks_read as index_blocks_read,
        idx_blks_hit as index_blocks_hit,
        CASE WHEN (idx_blks_read + idx_blks_hit) > 0
          THEN ROUND(idx_blks_hit::numeric / (idx_blks_read + idx_blks_hit)::numeric * 100, 2)
          ELSE 0
        END as index_hit_ratio,
        toast_blks_read as toast_blocks_read,
        toast_blks_hit as toast_blocks_hit,
        tidx_blks_read as toast_index_blocks_read,
        tidx_blks_hit as toast_index_blocks_hit
      FROM pg_statio_user_tables
      ORDER BY (heap_blks_read + idx_blks_read) DESC
      LIMIT 20;
    `;

    const result = await this.databaseService.query(ioStatsQuery);
    return result.rows;
  }

  async getBgWriterStats() {
    const bgWriterQuery = `
      SELECT
        checkpoints_timed as checkpoints_timed,
        checkpoints_req as checkpoints_requested,
        checkpoint_write_time as checkpoint_write_time_ms,
        checkpoint_sync_time as checkpoint_sync_time_ms,
        buffers_checkpoint as buffers_written_checkpoint,
        buffers_clean as buffers_written_bgwriter,
        maxwritten_clean as bgwriter_maxwritten_count,
        buffers_backend as buffers_written_backend,
        buffers_backend_fsync as buffers_fsync_backend,
        buffers_alloc as buffers_allocated,
        stats_reset as stats_reset
      FROM pg_stat_bgwriter;
    `;

    const result = await this.databaseService.query(bgWriterQuery);
    return result.rows[0];
  }
}
