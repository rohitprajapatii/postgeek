"use client";

import { useQuery } from "@tanstack/react-query";
import { api, type Row } from "@/lib/api";
import { StatCard } from "@/components/ui/stat-card";
import { Card, CardHeader, Badge, EmptyState } from "@/components/ui/primitives";
import { CardSkeleton, QueryError, TableSkeleton } from "@/components/ui/states";
import { DataTable, type Column } from "@/components/ui/data-table";
import { formatNumber, formatPercent, toNumber } from "@/lib/format";
import {
  AlertTriangle,
  Database,
  Gauge,
  HardDrive,
  Layers,
  ScanSearch,
  ShieldAlert,
  Trash2,
  Users,
} from "lucide-react";

export default function HealthPage() {
  const health = useQuery({ queryKey: ["healthOverview"], queryFn: api.healthOverview });
  const missing = useQuery({ queryKey: ["missingIndexes"], queryFn: api.missingIndexes });
  const unused = useQuery({ queryKey: ["unusedIndexes"], queryFn: api.unusedIndexes });
  const bloat = useQuery({ queryKey: ["tableBloat"], queryFn: api.tableBloat });

  const hl = (health.data ?? {}) as Row;
  const conn = (hl.connection_count ?? {}) as Row;
  const cache = (hl.cache_hit_ratio ?? {}) as Row;
  const dbSize = (hl.database_size ?? {}) as Row;
  const deadlocks = (hl.deadlocks ?? {}) as Row;
  const vacuum = Array.isArray(hl.vacuum_status) ? (hl.vacuum_status as Row[]) : [];

  // ratio is null until the database has served at least one table block
  // (brand-new database) — don't render that as a red 0%.
  const hasCacheData = cache.ratio !== null && cache.ratio !== undefined;
  const cacheRatio = toNumber(cache.ratio) * 100;
  const usedConn = toNumber(conn.used);
  const freeConn = toNumber(conn.free);

  return (
    <div className="space-y-6">
      {/* Overview */}
      {health.isLoading ? (
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
          {Array.from({ length: 4 }).map((_, i) => (
            <CardSkeleton key={i} />
          ))}
        </div>
      ) : health.isError ? (
        <QueryError error={health.error} onRetry={() => health.refetch()} />
      ) : (
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
          <StatCard
            label="Cache hit ratio"
            value={hasCacheData ? formatPercent(cacheRatio) : "—"}
            icon={Gauge}
            tone={
              !hasCacheData
                ? "neutral"
                : cacheRatio >= 95
                  ? "teal"
                  : cacheRatio >= 90
                    ? "amber"
                    : "rose"
            }
            hint={
              !hasCacheData
                ? "No table I/O recorded yet"
                : cacheRatio >= 99
                  ? "Excellent"
                  : "From heap reads"
            }
          />
          <StatCard label="Database size" value={String(dbSize.pretty_size ?? "—")} icon={HardDrive} tone="brand" />
          <StatCard
            label="Connections free"
            value={formatNumber(freeConn)}
            icon={Users}
            tone="violet"
            hint={`${formatNumber(usedConn)} in use`}
          />
          <StatCard
            label="Deadlocks"
            value={formatNumber(deadlocks.deadlocks)}
            icon={ShieldAlert}
            tone={toNumber(deadlocks.deadlocks) > 0 ? "rose" : "neutral"}
            hint="since last reset"
          />
        </div>
      )}

      {/* Vacuum / dead tuples */}
      <Card>
        <CardHeader
          title="Dead tuples & vacuum status"
          subtitle="Tables with the most dead tuples"
          icon={<Trash2 className="h-4 w-4" />}
        />
        <div className="mt-3">
          {health.isLoading ? (
            <TableSkeleton rows={4} />
          ) : vacuum.length ? (
            <DataTable
              rows={vacuum}
              rowKey={(r, i) => `${r.table_name}-${i}`}
              columns={
                [
                  { key: "table_name", header: "Table", render: (r) => <TableName schema={r.schema} table={r.table_name} /> },
                  { key: "dead_tuples", header: "Dead", align: "right", render: (r) => formatNumber(r.dead_tuples) },
                  { key: "live_tuples", header: "Live", align: "right", render: (r) => formatNumber(r.live_tuples) },
                  {
                    key: "dead_tuples_ratio",
                    header: "Dead %",
                    align: "right",
                    render: (r) => <RatioBadge value={toNumber(r.dead_tuples_ratio)} />,
                  },
                  { key: "last_autovacuum", header: "Last autovacuum", render: (r) => fmtDate(r.last_autovacuum) },
                ] as Column<Row>[]
              }
            />
          ) : (
            <EmptyState icon={<Trash2 className="h-5 w-5" />} title="No dead tuples" description="All tables are clean." />
          )}
        </div>
      </Card>

      <div className="grid grid-cols-1 gap-4 lg:grid-cols-2">
        {/* Missing indexes */}
        <Card>
          <CardHeader
            title="Possibly missing indexes"
            subtitle="High sequential scan activity"
            icon={<ScanSearch className="h-4 w-4" />}
          />
          <div className="mt-3">
            {missing.isLoading ? (
              <TableSkeleton rows={4} />
            ) : missing.isError ? (
              <QueryError error={missing.error} onRetry={() => missing.refetch()} />
            ) : (missing.data ?? []).length ? (
              <DataTable
                dense
                rows={missing.data as Row[]}
                rowKey={(r, i) => `${r.table_name}-${i}`}
                columns={
                  [
                    { key: "table_name", header: "Table", render: (r) => <TableName schema={r.schema} table={r.table_name} /> },
                    { key: "sequential_scans", header: "Seq scans", align: "right", render: (r) => formatNumber(r.sequential_scans) },
                    { key: "estimated_rows", header: "Rows", align: "right", render: (r) => formatNumber(r.estimated_rows) },
                    { key: "avg_rows_per_scan", header: "Avg/scan", align: "right", render: (r) => formatNumber(r.avg_rows_per_scan) },
                  ] as Column<Row>[]
                }
              />
            ) : (
              <EmptyState icon={<ScanSearch className="h-5 w-5" />} title="No index suggestions" description="Sequential scan patterns look healthy." />
            )}
          </div>
        </Card>

        {/* Unused indexes */}
        <Card>
          <CardHeader
            title="Unused indexes"
            subtitle="Rarely scanned, consuming space"
            icon={<Layers className="h-4 w-4" />}
          />
          <div className="mt-3">
            {unused.isLoading ? (
              <TableSkeleton rows={4} />
            ) : unused.isError ? (
              <QueryError error={unused.error} onRetry={() => unused.refetch()} />
            ) : (unused.data ?? []).length ? (
              <DataTable
                dense
                rows={unused.data as Row[]}
                rowKey={(r, i) => `${r.index_name}-${i}`}
                columns={
                  [
                    { key: "index_name", header: "Index", render: (r) => <code className="font-mono text-xs">{String(r.index_name)}</code> },
                    { key: "table_name", header: "Table", render: (r) => String(r.table_name) },
                    { key: "index_scans", header: "Scans", align: "right", render: (r) => formatNumber(r.index_scans) },
                    { key: "index_size", header: "Size", align: "right", render: (r) => <Badge tone="amber">{String(r.index_size)}</Badge> },
                  ] as Column<Row>[]
                }
              />
            ) : (
              <EmptyState icon={<Layers className="h-5 w-5" />} title="No unused indexes" description="Every index is earning its keep." />
            )}
          </div>
        </Card>
      </div>

      {/* Table bloat */}
      <Card>
        <CardHeader
          title="Table bloat"
          subtitle="Estimated wasted space from dead rows"
          icon={<Database className="h-4 w-4" />}
        />
        <div className="mt-3">
          {bloat.isLoading ? (
            <TableSkeleton rows={4} />
          ) : !Array.isArray(bloat.data) ? (
            <EmptyState
              icon={<AlertTriangle className="h-5 w-5" />}
              title="Bloat statistics unavailable"
              description="Could not calculate table bloat for this database."
            />
          ) : (bloat.data as Row[]).length ? (
            <DataTable
              rows={bloat.data as Row[]}
              rowKey={(r, i) => `${r.table_name}-${i}`}
              columns={
                [
                  { key: "table_name", header: "Table", render: (r) => <TableName schema={r.schema} table={r.table_name} /> },
                  { key: "live_tuples", header: "Live", align: "right", render: (r) => formatNumber(r.live_tuples) },
                  { key: "dead_tuples", header: "Dead", align: "right", render: (r) => formatNumber(r.dead_tuples) },
                  { key: "bloat_ratio", header: "Bloat %", align: "right", render: (r) => <RatioBadge value={toNumber(r.bloat_ratio)} /> },
                  { key: "table_size", header: "Size", align: "right", render: (r) => <Badge tone="neutral">{String(r.table_size)}</Badge> },
                ] as Column<Row>[]
              }
            />
          ) : (
            <EmptyState icon={<Database className="h-5 w-5" />} title="No significant bloat" description="Tables are compact and healthy." />
          )}
        </div>
      </Card>
    </div>
  );
}

function TableName({ schema, table }: { schema: unknown; table: unknown }) {
  return (
    <span className="font-medium text-ink">
      <span className="text-ink-muted">{String(schema)}.</span>
      {String(table)}
    </span>
  );
}

function RatioBadge({ value }: { value: number }) {
  const tone = value >= 50 ? "rose" : value >= 20 ? "amber" : "teal";
  return <Badge tone={tone as never}>{value.toFixed(1)}%</Badge>;
}

function fmtDate(value: unknown): string {
  if (!value) return "Never";
  const d = new Date(String(value));
  if (Number.isNaN(d.getTime())) return "—";
  return d.toLocaleString("en-US", { month: "short", day: "numeric", hour: "2-digit", minute: "2-digit" });
}
