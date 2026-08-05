const STORAGE_KEY = "postgeek.apiUrl";

export const DEFAULT_API_URL =
  process.env.NEXT_PUBLIC_DEFAULT_API_URL || "http://localhost:3000";

export function getApiUrl(): string {
  if (typeof window === "undefined") return DEFAULT_API_URL;
  return window.localStorage.getItem(STORAGE_KEY) || DEFAULT_API_URL;
}

export function setApiUrl(url: string) {
  if (typeof window === "undefined") return;
  window.localStorage.setItem(STORAGE_KEY, url.replace(/\/$/, ""));
}

export class ApiError extends Error {
  status: number;
  constructor(message: string, status: number) {
    super(message);
    this.name = "ApiError";
    this.status = status;
  }
}

function extractMessage(data: unknown, status: number): string {
  if (typeof data === "string" && data) return data;
  if (data && typeof data === "object") {
    const obj = data as Record<string, unknown>;
    const raw = obj.message ?? obj.error;
    if (Array.isArray(raw) && raw.length) return String(raw[0]);
    if (typeof raw === "string") return raw;
  }
  return `Request failed (${status})`;
}

async function request<T>(
  method: string,
  path: string,
  options: { body?: unknown; query?: Record<string, unknown> } = {},
): Promise<T> {
  const base = getApiUrl();
  const url = new URL(`${base}/api${path}`);
  if (options.query) {
    for (const [key, value] of Object.entries(options.query)) {
      if (value !== undefined && value !== null) {
        url.searchParams.set(key, String(value));
      }
    }
  }

  let res: Response;
  try {
    res = await fetch(url.toString(), {
      method,
      headers: options.body ? { "Content-Type": "application/json" } : undefined,
      body: options.body ? JSON.stringify(options.body) : undefined,
      cache: "no-store",
    });
  } catch {
    throw new ApiError(
      "Could not reach the backend. Check the API URL and that the server is running.",
      0,
    );
  }

  const text = await res.text();
  let data: unknown = null;
  if (text) {
    try {
      data = JSON.parse(text);
    } catch {
      data = text;
    }
  }

  if (!res.ok) {
    throw new ApiError(extractMessage(data, res.status), res.status);
  }
  return data as T;
}

export interface ConnectionPayload {
  connectionString?: string;
  host?: string;
  port?: number;
  database?: string;
  username?: string;
  password?: string;
}

export interface PaginatedResponse<T> {
  success: boolean;
  data: T[];
  pagination?: {
    page: number;
    limit: number;
    total: number;
    totalPages: number;
  };
}

export interface ColumnInfo {
  columnName: string;
  dataType: string;
  isNullable: boolean;
  defaultValue: string | null;
  maxLength: number | null;
  isIdentity: boolean;
  isPrimaryKey: boolean;
  isForeignKey: boolean;
  references?: { table: string; column: string; schema: string };
}

export interface TableInfo {
  tableName: string;
  schemaName: string;
  rowCount: number;
  columns: ColumnInfo[];
  primaryKeys: string[];
  foreignKeys: unknown[];
  indexes: { indexName: string; columns: string[]; isUnique: boolean; isPrimary: boolean }[];
}

export interface SchemaInfo {
  schemaName: string;
  tables: { tableName: string; rowCount: number }[];
}

export interface QueryResult {
  rows: Record<string, unknown>[];
  fields: { name: string; dataType: string }[];
  rowCount: number;
  executionTime: number;
}

export type Row = Record<string, unknown>;

export interface Filter {
  column: string;
  operator: string;
  value: string;
}

export interface PlanNode {
  "Node Type": string;
  "Relation Name"?: string;
  Alias?: string;
  "Startup Cost"?: number;
  "Total Cost"?: number;
  "Plan Rows"?: number;
  "Plan Width"?: number;
  "Actual Total Time"?: number;
  "Actual Rows"?: number;
  "Actual Loops"?: number;
  "Index Name"?: string;
  "Join Type"?: string;
  Plans?: PlanNode[];
  [key: string]: unknown;
}

export const api = {
  // Connection
  connect: (payload: ConnectionPayload) =>
    request<{ success: boolean; message: string }>("POST", "/database/connect", {
      body: payload,
    }),
  disconnect: () =>
    request<{ success: boolean; message: string }>("DELETE", "/database/disconnect"),
  status: () =>
    request<{
      isConnected: boolean;
      database?: string;
      user?: string;
      host?: string;
      ssl?: boolean;
      serverVersionNum?: number;
      serverVersion?: string;
      [k: string]: unknown;
    }>("GET", "/database/status"),

  // Health
  healthOverview: () => request<Row>("GET", "/health"),
  missingIndexes: () => request<Row[]>("GET", "/health/missing-indexes"),
  unusedIndexes: () => request<Row[]>("GET", "/health/unused-indexes"),
  tableBloat: () => request<Row[]>("GET", "/health/table-bloat"),

  // Statistics
  overview: () => request<Row>("GET", "/statistics/overview"),
  tableStats: () => request<Row[]>("GET", "/statistics/tables"),
  indexStats: () => request<Row[]>("GET", "/statistics/indexes"),
  ioStats: () => request<Row[]>("GET", "/statistics/io"),
  bgWriterStats: () => request<Row>("GET", "/statistics/bgwriter"),

  // Activity
  activeSessions: () => request<Row[]>("GET", "/activity/sessions/active"),
  idleSessions: () => request<Row[]>("GET", "/activity/sessions/idle"),
  locks: () => request<Row[]>("GET", "/activity/locks"),
  blockedQueries: () => request<Row[]>("GET", "/activity/blocked"),
  terminateSession: (pid: number) =>
    request<{ success?: boolean; message?: string; error?: string }>(
      "DELETE",
      `/activity/sessions/${pid}`,
    ),

  // Queries
  slowQueries: (limit = 15) =>
    request<Row[] | { error: string; hint?: string }>("GET", "/queries/slow", {
      query: { limit },
    }),
  queryStats: () => request<Row>("GET", "/queries/stats"),
  queryTypes: () => request<Row[] | { error: string }>("GET", "/queries/types"),
  resetQueryStats: () =>
    request<{ success?: boolean; message?: string; error?: string }>("POST", "/queries/reset"),
  enablePgStatStatements: () =>
    request<{ success?: boolean; message?: string; error?: string; hint?: string }>(
      "POST",
      "/queries/enable-extension",
    ),

  // Data management
  schemas: () => request<{ success: boolean; data: SchemaInfo[] }>("GET", "/data-management/schemas"),
  tableInfo: (schema: string, table: string) =>
    request<{ success: boolean; data: TableInfo }>(
      "GET",
      `/data-management/tables/${encodeURIComponent(schema)}/${encodeURIComponent(table)}/info`,
    ),
  tableData: (
    schema: string,
    table: string,
    opts: {
      page?: number;
      limit?: number;
      sortBy?: string;
      sortOrder?: "ASC" | "DESC";
      filters?: Filter[];
    },
  ) => {
    const query: Record<string, unknown> = {
      page: opts.page,
      limit: opts.limit,
      sortBy: opts.sortBy,
      sortOrder: opts.sortOrder,
    };
    // Encode filters using bracket notation that Express/qs parses into objects.
    (opts.filters ?? []).forEach((f, i) => {
      query[`filters[${i}][column]`] = f.column;
      query[`filters[${i}][operator]`] = f.operator;
      query[`filters[${i}][value]`] = f.value;
    });
    return request<PaginatedResponse<Row>>(
      "GET",
      `/data-management/tables/${encodeURIComponent(schema)}/${encodeURIComponent(table)}/data`,
      { query },
    );
  },
  createRecord: (schema: string, table: string, data: Row) =>
    request<{ success: boolean; data: Row; message: string }>(
      "POST",
      `/data-management/tables/${encodeURIComponent(schema)}/${encodeURIComponent(table)}/records`,
      { body: { data } },
    ),
  updateRecord: (schema: string, table: string, data: Row, where: Row) =>
    request<{ success: boolean; data: Row[]; message: string }>(
      "PUT",
      `/data-management/tables/${encodeURIComponent(schema)}/${encodeURIComponent(table)}/records`,
      { body: { data, where } },
    ),
  deleteRecord: (schema: string, table: string, where: Row) =>
    request<{ success: boolean; data: { deletedCount: number }; message: string }>(
      "DELETE",
      `/data-management/tables/${encodeURIComponent(schema)}/${encodeURIComponent(table)}/records`,
      { body: { where } },
    ),
  exportTable: (schema: string, table: string, format: "csv" | "json", filters?: Filter[]) =>
    request<{ success: boolean; data: string; filename: string }>(
      "POST",
      `/data-management/tables/${encodeURIComponent(schema)}/${encodeURIComponent(table)}/export`,
      { body: { format, filters } },
    ),
  searchTables: (q: string) =>
    request<{ success: boolean; data: { schemaName: string; tableName: string; rowCount: number }[] }>(
      "GET",
      "/data-management/search/tables",
      { query: { q } },
    ),
  executeQuery: (query: string, readonly = true) =>
    request<{ success: boolean; data: QueryResult; message: string }>(
      "POST",
      "/data-management/query/execute",
      { body: { query, readonly } },
    ),
};
