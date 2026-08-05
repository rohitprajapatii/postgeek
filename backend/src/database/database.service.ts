import { Injectable, OnModuleInit, OnModuleDestroy } from "@nestjs/common";
import { Pool, PoolClient } from "pg";

@Injectable()
export class DatabaseService implements OnModuleInit, OnModuleDestroy {
  private pool: Pool;
  private connectedClient: PoolClient = null;
  private isConnected = false;
  private lastError: string | null = null;
  private connectionInfo: {
    database?: string;
    user?: string;
    host?: string;
    strategy?: string;
    ssl?: boolean;
    serverVersionNum?: number;
    serverVersion?: string;
  } = {};

  getLastError(): string | null {
    return this.lastError;
  }

  /**
   * Pick the most useful message from a set of failed connection attempts.
   * Authentication / host / permission errors are far more actionable than the
   * "server does not support SSL connections" noise produced by SSL fallbacks.
   */
  private pickBestError(errors: string[]): string {
    if (!errors.length) return "All connection strategies failed";
    const informative = errors.find((e) =>
      /password|authentic|role .* does not exist|database .* does not exist|permission|no pg_hba|timeout|ENOTFOUND|ECONNREFUSED|EHOSTUNREACH|getaddrinfo/i.test(
        e
      )
    );
    // De-prioritise the generic SSL-support message if anything better exists.
    const nonSsl = errors.find((e) => !/does not support SSL/i.test(e));
    return informative || nonSsl || errors[0];
  }

  async onModuleInit() {
    console.log(
      "[DatabaseService] PostgreSQL Dashboard - Universal Database Connector"
    );
    console.log(
      "[DatabaseService] Supports: Local, Docker, External databases in any combination"
    );
  }

  async onModuleDestroy() {
    console.log("[DatabaseService] Module destroying, disconnecting...");
    await this.disconnect();
  }

  /**
   * Comprehensive environment detection
   */
  private getEnvironmentInfo() {
    const isInDocker = this.isRunningInDocker();
    const dockerNetworkInfo = this.getDockerNetworkInfo();

    return {
      isInDocker,
      platform: process.platform,
      nodeEnv: process.env.NODE_ENV,
      dockerNetworkInfo,
    };
  }

  /**
   * Check if we're running in Docker with multiple detection methods
   */
  private isRunningInDocker(): boolean {
    try {
      const fs = require("fs");
      const indicators = [
        // Environment variables
        process.env.DOCKER_ENV === "true",
        // Docker files
        fs.existsSync("/.dockerenv"),
        // Control groups (Linux)
        fs.existsSync("/proc/1/cgroup") &&
          fs.readFileSync("/proc/1/cgroup", "utf8").includes("docker"),
        // Process ID 1 check (Docker containers typically have init as PID 1)
        process.pid === 1 && process.platform === "linux",
        // Container-specific paths
        fs.existsSync("/proc/self/mountinfo") &&
          fs.readFileSync("/proc/self/mountinfo", "utf8").includes("docker"),
      ];

      return indicators.some((indicator) => indicator);
    } catch (error) {
      console.log(
        "[DatabaseService] Docker detection failed, assuming local environment"
      );
      return false;
    }
  }

  /**
   * Get Docker network information for advanced routing
   */
  private getDockerNetworkInfo() {
    try {
      const fs = require("fs");
      const os = require("os");

      const networkInfo = {
        defaultGateway: null,
        dockerGateway: null,
        hostAliases: [],
      };

      // Try to get default gateway
      if (fs.existsSync("/proc/net/route")) {
        const routeTable = fs.readFileSync("/proc/net/route", "utf8");
        const lines = routeTable.split("\n");
        for (const line of lines) {
          const parts = line.split("\t");
          if (parts[1] === "00000000") {
            // Default route
            const gatewayHex = parts[2];
            if (gatewayHex && gatewayHex !== "00000000") {
              // Convert hex to IP
              const ip = [
                parseInt(gatewayHex.substr(6, 2), 16),
                parseInt(gatewayHex.substr(4, 2), 16),
                parseInt(gatewayHex.substr(2, 2), 16),
                parseInt(gatewayHex.substr(0, 2), 16),
              ].join(".");
              networkInfo.defaultGateway = ip;
              break;
            }
          }
        }
      }

      // Common Docker gateways
      networkInfo.dockerGateway = networkInfo.defaultGateway || "172.17.0.1";

      // Host aliases
      networkInfo.hostAliases = [
        "host.docker.internal",
        "gateway.docker.internal",
        networkInfo.dockerGateway,
        "172.17.0.1",
        "172.18.0.1",
        "172.19.0.1",
      ].filter((ip) => ip);

      return networkInfo;
    } catch (error) {
      return {
        defaultGateway: "172.17.0.1",
        dockerGateway: "172.17.0.1",
        hostAliases: ["host.docker.internal", "172.17.0.1"],
      };
    }
  }

  /**
   * Analyze connection string to determine database location and type
   */
  private analyzeConnectionString(connectionString: string) {
    const analysis = {
      isLocalhost: false,
      isDockerContainer: false,
      isExternal: false,
      host: "",
      port: 5432,
      requiresSSL: false,
      connectionType: "unknown",
    };

    try {
      let host = "";
      let port = 5432;

      try {
        const url = new URL(connectionString);
        host = url.hostname;
        port = parseInt(url.port) || 5432;
      } catch {
        // Fallback parser for connection strings with unencoded special
        // characters in the password (common with cloud providers). We only
        // need the host:port, which lives after the last '@'.
        const at = connectionString.lastIndexOf("@");
        if (at !== -1) {
          let rest = connectionString.slice(at + 1).split("/")[0].split("?")[0];
          // Strip IPv6 brackets if present
          if (rest.startsWith("[")) {
            const close = rest.indexOf("]");
            host = rest.slice(1, close);
            const after = rest.slice(close + 1);
            port = parseInt(after.replace(/^:/, "")) || 5432;
          } else {
            const parts = rest.split(":");
            host = parts[0];
            port = parseInt(parts[1]) || 5432;
          }
        }
      }

      analysis.host = host;
      analysis.port = port;

      // SSL detection (regex so it works even when URL parsing fails)
      const sslMatch = connectionString.match(/[?&](?:sslmode|ssl)=([^&\s]+)/i);
      const mode = sslMatch ? sslMatch[1].toLowerCase() : null;
      analysis.requiresSSL =
        mode === "require" ||
        mode === "verify-ca" ||
        mode === "verify-full" ||
        mode === "true";

      // Determine connection type
      if (["localhost", "127.0.0.1", "::1", ""].includes(analysis.host)) {
        analysis.isLocalhost = true;
        analysis.connectionType = "localhost";
      } else if (
        analysis.host.match(/^172\.(1[6-9]|2\d|3[01])\./) ||
        analysis.host.match(/^192\.168\./) ||
        analysis.host.endsWith(".docker.internal") ||
        analysis.host.includes("docker")
      ) {
        analysis.isDockerContainer = true;
        analysis.connectionType = "docker-network";
      } else {
        analysis.isExternal = true;
        analysis.connectionType = "external";
      }
    } catch (error) {
      console.log(
        "[DatabaseService] Could not parse connection string for analysis"
      );
    }

    return analysis;
  }

  /**
   * Determine the ordered list of SSL options to try for a target. Cloud /
   * managed databases almost always require SSL, while local instances almost
   * never use it — so we order attempts by what is most likely to succeed.
   */
  private getSslOptions(
    connectionString: string,
    dbAnalysis: { isExternal: boolean }
  ): Array<false | { rejectUnauthorized: boolean }> {
    const sslOn = { rejectUnauthorized: false };
    const match = connectionString.match(/[?&](?:sslmode|ssl)=([^&\s]+)/i);
    const mode = match ? match[1].toLowerCase() : null;

    if (mode) {
      if (["require", "verify-ca", "verify-full", "true", "1", "yes"].includes(mode)) {
        return [sslOn];
      }
      if (["disable", "false", "0", "no"].includes(mode)) {
        return [false];
      }
      // prefer / allow → try SSL first, then plaintext
      return [sslOn, false];
    }

    // No explicit preference: managed DBs usually need SSL, local usually not.
    return dbAnalysis.isExternal ? [sslOn, false] : [false, sslOn];
  }

  /**
   * Generate all possible connection strategies based on environment and target.
   * Each strategy carries both a host variant and an explicit SSL setting.
   */
  private generateConnectionStrategies(
    originalConnectionString: string
  ): Array<{
    connectionString: string;
    ssl: false | { rejectUnauthorized: boolean };
    description: string;
  }> {
    const envInfo = this.getEnvironmentInfo();
    const dbAnalysis = this.analyzeConnectionString(originalConnectionString);

    console.log("[DatabaseService] Environment Analysis:", {
      appInDocker: envInfo.isInDocker,
      dbType: dbAnalysis.connectionType,
      platform: envInfo.platform,
    });

    // 1) Build ordered host variants (the original always comes first).
    const hostVariants: { connectionString: string; description: string }[] = [
      { connectionString: originalConnectionString, description: "Original host" },
    ];

    if (dbAnalysis.isLocalhost && envInfo.isInDocker) {
      console.log("[DatabaseService] Detected: App in Docker → Localhost DB");
      hostVariants.push({
        connectionString: originalConnectionString.replace(
          /localhost|127\.0\.0\.1/g,
          "host.docker.internal"
        ),
        description: "host.docker.internal",
      });
      envInfo.dockerNetworkInfo.hostAliases.forEach((alias) => {
        hostVariants.push({
          connectionString: originalConnectionString.replace(
            /localhost|127\.0\.0\.1/g,
            alias
          ),
          description: `Docker gateway ${alias}`,
        });
      });
    } else if (dbAnalysis.isDockerContainer && !envInfo.isInDocker) {
      console.log("[DatabaseService] Detected: Local App → Docker DB");
      hostVariants.push({
        connectionString: originalConnectionString.replace(
          /172\.\d+\.\d+\.\d+|[^@/]*\.docker\.internal/g,
          "localhost"
        ),
        description: "Map Docker container → localhost",
      });
    } else if (dbAnalysis.isDockerContainer && envInfo.isInDocker) {
      console.log("[DatabaseService] Detected: Docker App → Docker DB");
      hostVariants.push({
        connectionString: originalConnectionString.replace(
          /172\.\d+\.\d+\.\d+/g,
          "host.docker.internal"
        ),
        description: "Docker inter-container via host",
      });
    }

    // De-duplicate host variants (a no-op replace yields the original again).
    const seen = new Set<string>();
    const uniqueHosts = hostVariants.filter((h) => {
      if (seen.has(h.connectionString)) return false;
      seen.add(h.connectionString);
      return true;
    });

    // 2) Determine SSL options for this target.
    const sslOptions = this.getSslOptions(originalConnectionString, dbAnalysis);

    // 3) Combine. Try every SSL option for the original host; for alternate
    //    host variants only use the primary SSL option to bound attempt count.
    const strategies: Array<{
      connectionString: string;
      ssl: false | { rejectUnauthorized: boolean };
      description: string;
    }> = [];

    uniqueHosts.forEach((host, hostIdx) => {
      const opts = hostIdx === 0 ? sslOptions : sslOptions.slice(0, 1);
      opts.forEach((ssl) => {
        strategies.push({
          connectionString: host.connectionString,
          ssl,
          description: `${host.description} · SSL ${ssl ? "on" : "off"}`,
        });
      });
    });

    return strategies;
  }

  /**
   * Create optimized pool configuration
   */
  private createPoolConfig(
    connectionString: string,
    ssl: false | { rejectUnauthorized: boolean },
    dbAnalysis: any,
    envInfo: any
  ) {
    const isLocal = dbAnalysis.isLocalhost || dbAnalysis.isDockerContainer;

    return {
      connectionString,
      // Connection pool settings. min:0 so we never pin an idle connection,
      // which matters for managed DBs with tight connection limits.
      idleTimeoutMillis: 30000,
      max: 5,
      min: 0,
      // Timeouts based on connection type
      connectionTimeoutMillis: isLocal ? 7000 : 15000,
      query_timeout: 60000,
      statement_timeout: 60000,
      // Explicit SSL setting decided per strategy
      ssl,
      // Keep alive for external connections
      keepAlive: !isLocal,
      keepAliveInitialDelayMillis: !isLocal ? 10000 : 0,
      // Application name for debugging
      application_name: `postgeek-${envInfo.isInDocker ? "docker" : "local"}`,
    };
  }

  /**
   * Try a specific connection strategy
   */
  private async tryConnectionStrategy(
    strategy: any,
    dbAnalysis: any,
    envInfo: any
  ): Promise<boolean> {
    console.log(`[DatabaseService] Trying: ${strategy.description}`);
    console.log(
      `[DatabaseService] Connection: ${strategy.connectionString.replace(/\/\/[^@]+@/, "//***:***@")}`
    );

    const poolConfig = this.createPoolConfig(
      strategy.connectionString,
      strategy.ssl,
      dbAnalysis,
      envInfo
    );
    const tempPool = new Pool(poolConfig);

    try {
      const client = await tempPool.connect();

      // Test with a simple query
      const result = await client.query(
        `SELECT version(), current_database(), current_user,
                current_setting('server_version_num')::int AS server_version_num,
                current_setting('server_version') AS server_version`
      );

      // Return the client to the pool — queries use pool.query(), so we do
      // not pin a dedicated client for the connection's lifetime.
      client.release();

      this.pool = tempPool;
      this.connectedClient = null;
      this.connectionInfo = {
        database: result.rows[0].current_database,
        user: result.rows[0].current_user,
        host: dbAnalysis.host,
        strategy: strategy.description,
        ssl: Boolean(strategy.ssl),
        // Exposed so the UI can gate version-dependent features
        // (e.g. EXPLAIN GENERIC_PLAN requires PostgreSQL 16+).
        serverVersionNum: result.rows[0].server_version_num,
        serverVersion: result.rows[0].server_version,
      };

      console.log(`[DatabaseService] ✅ SUCCESS with ${strategy.description}`);
      console.log(
        `[DatabaseService] Connected to: ${result.rows[0].current_database} as ${result.rows[0].current_user}`
      );

      return true;
    } catch (error) {
      this.lastError = error.message;
      console.log(
        `[DatabaseService] ❌ Failed with ${strategy.description}: ${error.message}`
      );
      await tempPool.end().catch(() => {});
      return false;
    }
  }

  async connect(connectionString: string): Promise<boolean> {
    console.log("\n" + "=".repeat(70));
    console.log("🔗 POSTGRESQL DASHBOARD - UNIVERSAL DATABASE CONNECTOR");
    console.log("=".repeat(70));

    if (!connectionString) {
      console.error("[DatabaseService] ❌ No connection string provided");
      this.lastError = "No connection string provided";
      return false;
    }

    this.lastError = null;
    const envInfo = this.getEnvironmentInfo();
    const dbAnalysis = this.analyzeConnectionString(connectionString);

    console.log("[DatabaseService] Connection Analysis:");
    console.log(
      `   • Application Environment: ${envInfo.isInDocker ? "Docker Container" : "Local"}`
    );
    console.log(`   • Database Type: ${dbAnalysis.connectionType}`);
    console.log(`   • Target Host: ${dbAnalysis.host}:${dbAnalysis.port}`);
    console.log(`   • SSL Required: ${dbAnalysis.requiresSSL ? "Yes" : "No"}`);
    console.log(`   • Platform: ${envInfo.platform}`);

    try {
      // Close any existing connections
      await this.disconnect();

      // Generate all possible connection strategies
      const strategies = this.generateConnectionStrategies(connectionString);
      console.log(
        `[DatabaseService] Generated ${strategies.length} connection strategies`
      );

      // Try each strategy, collecting errors so we can report the best one.
      const attemptErrors: string[] = [];
      for (let i = 0; i < strategies.length; i++) {
        const strategy = strategies[i];
        console.log(
          `\n[DatabaseService] Strategy ${i + 1}/${strategies.length}: ${strategy.description}`
        );

        const success = await this.tryConnectionStrategy(
          strategy,
          dbAnalysis,
          envInfo
        );
        if (!success && this.lastError) attemptErrors.push(this.lastError);
        if (success) {
          // Verify connection with additional queries
          await this.verifyConnection();
          this.isConnected = true;

          console.log("\n" + "✅".repeat(20));
          console.log("🎉 DATABASE CONNECTION ESTABLISHED SUCCESSFULLY!");
          console.log(`🔧 Strategy Used: ${strategy.description}`);
          console.log(`🎯 Connection Type: ${dbAnalysis.connectionType}`);
          console.log("✅".repeat(20) + "\n");

          return true;
        }
      }

      // If all strategies failed
      console.log("\n" + "❌".repeat(20));
      console.log("💥 ALL CONNECTION STRATEGIES FAILED");
      console.log("❌".repeat(20));
      await this.provideDetailedGuidance(connectionString, dbAnalysis, envInfo);

      this.lastError = this.pickBestError(attemptErrors);
      this.isConnected = false;
      return false;
    } catch (error) {
      console.error(
        "[DatabaseService] ❌ Unexpected error during connection:",
        error.message
      );
      this.isConnected = false;
      await this.disconnect();
      return false;
    }
  }

  /**
   * Verify connection with comprehensive database information
   */
  private async verifyConnection() {
    try {
      // Get PostgreSQL version and basic info
      const versionResult = await this.pool.query(
        "SELECT version(), current_database(), current_user, inet_server_addr(), inet_server_port()"
      );
      const version = versionResult.rows[0];

      // Check extensions
      const extensionResult = await this.pool.query(
        "SELECT EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_stat_statements') as has_pg_stat_statements"
      );

      // Check permissions
      const permissionsResult = await this.pool.query(`
        SELECT 
          has_database_privilege(current_user, current_database(), 'CONNECT') as can_connect,
          has_schema_privilege(current_user, 'pg_catalog', 'USAGE') as can_use_catalog,
          has_table_privilege(current_user, 'pg_stat_activity', 'SELECT') as can_monitor
      `);

      console.log("[DatabaseService] Database Information:");
      console.log(
        `   • Version: ${version.version.split(" ")[0]} ${version.version.split(" ")[1]}`
      );
      console.log(`   • Database: ${version.current_database}`);
      console.log(`   • User: ${version.current_user}`);
      console.log(
        `   • Server Address: ${version.inet_server_addr || "localhost"}`
      );
      console.log(`   • Server Port: ${version.inet_server_port || "default"}`);
      console.log(
        `   • pg_stat_statements: ${extensionResult.rows[0].has_pg_stat_statements ? "Available" : "Not installed"}`
      );
      console.log(
        `   • Monitoring Permissions: ${permissionsResult.rows[0].can_monitor ? "Yes" : "Limited"}`
      );
    } catch (error) {
      console.log(
        "[DatabaseService] Warning: Could not verify all database details:",
        error.message
      );
    }
  }

  /**
   * Provide comprehensive troubleshooting guidance
   */
  private async provideDetailedGuidance(
    connectionString: string,
    dbAnalysis: any,
    envInfo: any
  ) {
    console.log("\n" + "🔧 COMPREHENSIVE TROUBLESHOOTING GUIDE");
    console.log("=".repeat(50));

    // Scenario-specific guidance
    if (envInfo.isInDocker && dbAnalysis.isLocalhost) {
      console.log("📋 SCENARIO: Docker App → Localhost Database");
      console.log("💡 Solutions:");
      console.log("   1. Ensure PostgreSQL is running on your host machine");
      console.log("   2. Check PostgreSQL configuration:");
      console.log("      • listen_addresses = '*' in postgresql.conf");
      console.log("      • Add 'host all all 0.0.0.0/0 md5' in pg_hba.conf");
      console.log("   3. Restart PostgreSQL service");
      console.log(
        "   4. Verify with: docker exec -it container_name psql -h host.docker.internal -p 5432 -U user"
      );
    } else if (!envInfo.isInDocker && dbAnalysis.isDockerContainer) {
      console.log("📋 SCENARIO: Local App → Docker Database");
      console.log("💡 Solutions:");
      console.log("   1. Ensure Docker container is running and exposed:");
      console.log("      • docker run -p 5432:5432 postgres");
      console.log("   2. Use localhost:5432 instead of container IPs");
      console.log("   3. Check Docker port mapping: docker ps");
      console.log("   4. Verify with: psql -h localhost -p 5432 -U user");
    } else if (envInfo.isInDocker && dbAnalysis.isDockerContainer) {
      console.log("📋 SCENARIO: Docker App → Docker Database");
      console.log("💡 Solutions:");
      console.log("   1. Use Docker Compose for same network");
      console.log("   2. Use service names as hostnames");
      console.log("   3. Ensure containers can communicate");
      console.log("   4. Check Docker network: docker network ls");
    } else if (dbAnalysis.isExternal) {
      console.log("📋 SCENARIO: Any App → External Database");
      console.log("💡 Solutions:");
      console.log("   1. Check internet connectivity");
      console.log("   2. Verify credentials and permissions");
      console.log("   3. Check firewall and security groups");
      console.log("   4. Try SSL connection variants");
    }

    console.log("\n📞 Connection Details:");
    console.log(
      `   • Original String: ${connectionString.replace(/\/\/[^@]+@/, "//***:***@")}`
    );
    console.log(`   • Database Host: ${dbAnalysis.host}`);
    console.log(`   • Database Port: ${dbAnalysis.port}`);
    console.log(
      `   • App Environment: ${envInfo.isInDocker ? "Docker" : "Local"}`
    );
    console.log(`   • Platform: ${envInfo.platform}`);
    console.log("=".repeat(50) + "\n");
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
    this.connectionInfo = {};
  }

  async query(text: string, params: any[] = []): Promise<any> {
    if (!this.isConnected) {
      throw new Error("Not connected to any database. Please connect first.");
    }

    try {
      const result = await this.pool.query(text, params);
      return result;
    } catch (error) {
      console.error("[DatabaseService] Query failed:", error.message);
      throw error;
    }
  }

  getConnectionStatus(): {
    isConnected: boolean;
    database?: string;
    user?: string;
    host?: string;
    ssl?: boolean;
    serverVersionNum?: number;
    serverVersion?: string;
  } {
    return { isConnected: this.isConnected, ...this.connectionInfo };
  }
}
