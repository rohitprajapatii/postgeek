import { Injectable, OnModuleInit, OnModuleDestroy } from '@nestjs/common';
import { Pool, PoolClient } from 'pg';

@Injectable()
export class DatabaseService implements OnModuleInit, OnModuleDestroy {
  private pool: Pool;
  private connectedClient: PoolClient = null;
  private isConnected = false;

  async onModuleInit() {
    // Initialize without connecting to any specific database yet
  }

  async onModuleDestroy() {
    await this.disconnect();
  }

  async connect(connectionString: string): Promise<boolean> {
    try {
      // Close any existing connections
      await this.disconnect();

      // Create a new pool with the provided connection string
      this.pool = new Pool({
        connectionString,
        // Don't keep idle connections for too long
        idleTimeoutMillis: 30000,
        // Limit max connections
        max: 5,
      });

      // Test the connection by getting a client
      this.connectedClient = await this.pool.connect();
      this.isConnected = true;
      
      // Verify PostgreSQL version and access rights
      const versionResult = await this.connectedClient.query('SELECT version()');
      const version = versionResult.rows[0].version;
      
      // Check if pg_stat_statements extension is available
      const extensionResult = await this.connectedClient.query(
        "SELECT EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_stat_statements')"
      );
      const hasStatStatements = extensionResult.rows[0].exists;
      
      // Check for monitoring role permissions
      const permissionsResult = await this.connectedClient.query(
        "SELECT has_database_privilege(current_user, current_database(), 'CONNECT') as can_connect, " +
        "has_schema_privilege(current_user, 'pg_catalog', 'USAGE') as can_use_catalog"
      );
      
      console.log(`Connected to PostgreSQL: ${version}`);
      console.log(`pg_stat_statements available: ${hasStatStatements}`);
      
      return true;
    } catch (error) {
      console.error('Database connection error:', error.message);
      this.isConnected = false;
      return false;
    }
  }

  async disconnect(): Promise<void> {
    if (this.connectedClient) {
      this.connectedClient.release();
      this.connectedClient = null;
    }
    
    if (this.pool) {
      await this.pool.end();
      this.pool = null;
    }
    
    this.isConnected = false;
  }

  async query(text: string, params: any[] = []): Promise<any> {
    if (!this.isConnected) {
      throw new Error('Not connected to any database');
    }

    try {
      const result = await this.pool.query(text, params);
      return result;
    } catch (error) {
      console.error('Query execution error:', error.message);
      throw error;
    }
  }

  getConnectionStatus(): { isConnected: boolean } {
    return { isConnected: this.isConnected };
  }
}