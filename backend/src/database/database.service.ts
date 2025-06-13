import { Injectable, OnModuleInit, OnModuleDestroy } from "@nestjs/common";
import { Pool, PoolClient } from "pg";

@Injectable()
export class DatabaseService implements OnModuleInit, OnModuleDestroy {
  private pool: Pool;
  private connectedClient: PoolClient = null;
  private isConnected = false;

  async onModuleInit() {
    console.log("[DatabaseService] Module initialized");
    // Initialize without connecting to any specific database yet
  }

  async onModuleDestroy() {
    console.log("[DatabaseService] Module destroying, disconnecting...");
    await this.disconnect();
  }

  async connect(connectionString: string): Promise<boolean> {
    console.log("[DatabaseService] Starting connection attempt...");
    console.log(
      "[DatabaseService] Connection string format:",
      connectionString?.replace(/\/\/[^@]+@/, "//***:***@")
    );

    try {
      // Close any existing connections
      console.log("[DatabaseService] Closing any existing connections...");
      await this.disconnect();

      console.log("[DatabaseService] Creating new pool...");
      // Create a new pool with the provided connection string
      this.pool = new Pool({
        connectionString,
        // Don't keep idle connections for too long
        idleTimeoutMillis: 30000,
        // Limit max connections
        max: 5,
      });

      console.log(
        "[DatabaseService] Pool created, attempting to get client..."
      );
      // Test the connection by getting a client
      this.connectedClient = await this.pool.connect();
      console.log("[DatabaseService] Client acquired successfully");

      this.isConnected = true;
      console.log("[DatabaseService] Connection status set to true");

      console.log("[DatabaseService] Verifying PostgreSQL version...");
      // Verify PostgreSQL version and access rights
      const versionResult =
        await this.connectedClient.query("SELECT version()");
      const version = versionResult.rows[0].version;
      console.log("[DatabaseService] Version query successful");

      console.log("[DatabaseService] Checking pg_stat_statements extension...");
      // Check if pg_stat_statements extension is available
      const extensionResult = await this.connectedClient.query(
        "SELECT EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_stat_statements')"
      );
      const hasStatStatements = extensionResult.rows[0].exists;
      console.log(
        "[DatabaseService] Extension query successful",
        extensionResult.rows[0]
      );

      console.log("[DatabaseService] Checking permissions...");
      // Check for monitoring role permissions
      const permissionsResult = await this.connectedClient.query(
        "SELECT has_database_privilege(current_user, current_database(), 'CONNECT') as can_connect, " +
          "has_schema_privilege(current_user, 'pg_catalog', 'USAGE') as can_use_catalog"
      );
      console.log(
        "[DatabaseService] Permissions query successful",
        permissionsResult
      );

      console.log(`[DatabaseService] ✅ Connected to PostgreSQL: ${version}`);
      console.log(
        `[DatabaseService] pg_stat_statements available: ${hasStatStatements}`
      );
      console.log(`[DatabaseService] Connection established successfully`);

      return true;
    } catch (error) {
      console.error("[DatabaseService] ❌ Database connection failed");
      console.error("[DatabaseService] Error details:", {
        message: error.message,
        code: error.code,
        detail: error.detail,
        hint: error.hint,
        position: error.position,
        internalPosition: error.internalPosition,
        internalQuery: error.internalQuery,
        where: error.where,
        schema: error.schema,
        table: error.table,
        column: error.column,
        dataType: error.dataType,
        constraint: error.constraint,
        file: error.file,
        line: error.line,
        routine: error.routine,
        stack: error.stack,
      });

      this.isConnected = false;
      console.log(
        "[DatabaseService] Connection status set to false due to error"
      );

      // Clean up any partial connections
      await this.disconnect();

      return false;
    }
  }

  async disconnect(): Promise<void> {
    console.log("[DatabaseService] Starting disconnect process...");

    if (this.connectedClient) {
      console.log("[DatabaseService] Releasing connected client...");
      this.connectedClient.release();
      this.connectedClient = null;
      console.log("[DatabaseService] Client released");
    }

    if (this.pool) {
      console.log("[DatabaseService] Ending pool...");
      await this.pool.end();
      this.pool = null;
      console.log("[DatabaseService] Pool ended");
    }

    this.isConnected = false;
    console.log("[DatabaseService] Disconnect completed, status set to false");
  }

  async query(text: string, params: any[] = []): Promise<any> {
    console.log("[DatabaseService] Query execution requested:", {
      query: text.substring(0, 100) + (text.length > 100 ? "..." : ""),
      paramCount: params.length,
      isConnected: this.isConnected,
    });

    if (!this.isConnected) {
      console.error(
        "[DatabaseService] ❌ Query failed: Not connected to any database"
      );
      throw new Error("Not connected to any database");
    }

    try {
      const result = await this.pool.query(text, params);
      console.log("[DatabaseService] ✅ Query executed successfully:", {
        rowCount: result.rowCount,
        fieldCount: result.fields?.length || 0,
      });
      return result;
    } catch (error) {
      console.error("[DatabaseService] ❌ Query execution failed");
      console.error("[DatabaseService] Query error details:", {
        query: text,
        params: params,
        message: error.message,
        code: error.code,
        detail: error.detail,
        hint: error.hint,
        position: error.position,
        stack: error.stack,
      });
      throw error;
    }
  }

  getConnectionStatus(): { isConnected: boolean } {
    console.log("[DatabaseService] Connection status requested:", {
      isConnected: this.isConnected,
    });
    return { isConnected: this.isConnected };
  }
}
