import { Injectable } from '@nestjs/common';
import { DatabaseService } from '../database/database.service';

@Injectable()
export class ActivityService {
  constructor(private readonly databaseService: DatabaseService) {}

  async getActiveSessions() {
    const activeSessionsQuery = `
      SELECT
        pid,
        usename as username,
        application_name,
        client_addr as client_address,
        client_port,
        backend_start,
        xact_start as transaction_start,
        query_start,
        state_change,
        wait_event_type,
        wait_event,
        state,
        backend_xid as transaction_id,
        backend_xmin as transaction_min,
        query,
        EXTRACT(EPOCH FROM (now() - query_start)) as query_duration_seconds
      FROM pg_stat_activity
      WHERE state != 'idle'
        AND pid != pg_backend_pid()
      ORDER BY query_start;
    `;
    
    const result = await this.databaseService.query(activeSessionsQuery);
    return result.rows;
  }

  async getIdleSessions() {
    const idleSessionsQuery = `
      SELECT
        pid,
        usename as username,
        application_name,
        client_addr as client_address,
        client_port,
        backend_start,
        xact_start as transaction_start,
        query_start,
        state_change,
        state,
        query,
        EXTRACT(EPOCH FROM (now() - state_change)) as idle_duration_seconds
      FROM pg_stat_activity
      WHERE state = 'idle'
        AND pid != pg_backend_pid()
      ORDER BY state_change;
    `;
    
    const result = await this.databaseService.query(idleSessionsQuery);
    return result.rows;
  }

  async getLocks() {
    const locksQuery = `
      SELECT
        l.pid,
        l.locktype,
        l.mode,
        l.granted,
        l.fastpath,
        CASE
          WHEN l.relation IS NOT NULL THEN (SELECT relname FROM pg_class WHERE oid = l.relation)
          ELSE NULL
        END as relation_name,
        CASE
          WHEN l.page IS NOT NULL THEN l.page::text
          ELSE NULL
        END as page,
        CASE
          WHEN l.tuple IS NOT NULL THEN l.tuple::text
          ELSE NULL
        END as tuple,
        CASE
          WHEN l.transactionid IS NOT NULL THEN l.transactionid::text
          ELSE NULL
        END as transaction_id,
        CASE
          WHEN l.virtualtransaction IS NOT NULL THEN l.virtualtransaction::text
          ELSE NULL
        END as virtual_transaction_id,
        CASE
          WHEN l.objid IS NOT NULL THEN l.objid::text
          ELSE NULL
        END as object_id,
        sa.usename as username,
        sa.application_name,
        sa.client_addr as client_address,
        sa.query,
        EXTRACT(EPOCH FROM (now() - sa.query_start)) as query_duration_seconds,
        sa.wait_event_type,
        sa.wait_event
      FROM pg_locks l
      JOIN pg_stat_activity sa ON l.pid = sa.pid
      ORDER BY l.granted, l.pid;
    `;
    
    const result = await this.databaseService.query(locksQuery);
    return result.rows;
  }

  async getBlockedQueries() {
    const blockedQueriesQuery = `
      SELECT
        blocked.pid as blocked_pid,
        blocked.usename as blocked_user,
        blocked.application_name as blocked_application,
        blocked.client_addr as blocked_client,
        blocked.query as blocked_query,
        EXTRACT(EPOCH FROM (now() - blocked.query_start)) as blocked_duration_seconds,
        blocking.pid as blocking_pid,
        blocking.usename as blocking_user,
        blocking.application_name as blocking_application,
        blocking.client_addr as blocking_client,
        blocking.query as blocking_query,
        EXTRACT(EPOCH FROM (now() - blocking.query_start)) as blocking_duration_seconds
      FROM pg_stat_activity blocked
      JOIN pg_locks blocked_locks ON blocked.pid = blocked_locks.pid
      JOIN pg_locks blocking_locks 
        ON blocked_locks.database = blocking_locks.database
        AND blocked_locks.relation = blocking_locks.relation
        AND blocked_locks.page = blocking_locks.page
        AND blocked_locks.tuple = blocking_locks.tuple
        AND blocked_locks.virtualxid = blocking_locks.virtualxid
        AND blocked_locks.transactionid = blocking_locks.transactionid
        AND blocked_locks.classid = blocking_locks.classid
        AND blocked_locks.objid = blocking_locks.objid
        AND blocked_locks.objsubid = blocking_locks.objsubid
        AND blocked_locks.pid != blocking_locks.pid
      JOIN pg_stat_activity blocking ON blocking.pid = blocking_locks.pid
      WHERE NOT blocked_locks.granted
        AND blocking_locks.granted;
    `;
    
    const result = await this.databaseService.query(blockedQueriesQuery);
    return result.rows;
  }

  async terminateSession(pid: number) {
    try {
      await this.databaseService.query('SELECT pg_terminate_backend($1)', [pid]);
      return { success: true, message: `Session with PID ${pid} has been terminated` };
    } catch (error) {
      console.error(`Error terminating session ${pid}:`, error);
      return { error: error.message };
    }
  }
}