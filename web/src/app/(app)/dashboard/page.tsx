"use client";

import { useQuery } from "@tanstack/react-query";
import { api, type Row } from "@/lib/api";
import { StatCard } from "@/components/ui/stat-card";
import { Card, CardHeader, Badge, EmptyState } from "@/components/ui/primitives";
import { CardSkeleton, QueryError } from "@/components/ui/states";
import { DonutChart } from "@/components/charts/charts";
import {
  formatBytes,
  formatNumber,
  formatPercent,
  toNumber,
  formatMs,
  compactQuery,
  truncate,
} from "@/lib/format";
import {
  Activity,
  ArrowDownUp,
  Database,
  Gauge,
  HardDrive,
  Lock,
  Users,
  Zap,
} from "lucide-react";

export default function DashboardPage() {
  const overview = useQuery({ queryKey: ["overview"], queryFn: api.overview });
  const health = useQuery({ queryKey: ["health"], queryFn: api.healthOverview });
  const active = useQuery({
    queryKey: ["active"],
    queryFn: api.activeSessions,
    refetchInterval: 10_000,
  });
  const idle = useQuery({ queryKey: ["idle"], queryFn: api.idleSessions });
  const locks = useQuery({ queryKey: ["locks"], queryFn: api.locks });
  const blocked = useQuery({ queryKey: ["blocked"], queryFn: api.blockedQueries });
  const slow = useQuery({ queryKey: ["slow", 6], queryFn: () => api.slowQueries(6) });

  const ov = (overview.data ?? {}) as Row;
  const hl = (health.data ?? {}) as Row;
  const conn = (hl.connection_count ?? {}) as Row;

  const cacheRatio = toNumber(ov.cache_hit_ratio);
  const usedConn = toNumber(conn.used);
  const maxConn = toNumber(conn.max_conn);
  const activeCount = active.data?.length ?? 0;
  const idleCount = idle.data?.length ?? 0;
  const lockCount = locks.data?.length ?? 0;
  const blockedCount = blocked.data?.length ?? 0;

  const ioData = [
    { name: "Cache hits", value: toNumber(ov.blocks_hit) },
    { name: "Disk reads", value: toNumber(ov.blocks_read) },
  ];

  const dmlData = [
    { name: "Inserts", value: toNumber(ov.rows_inserted) },
    { name: "Updates", value: toNumber(ov.rows_updated) },
    { name: "Deletes", value: toNumber(ov.rows_deleted) },
  ].filter((d) => d.value > 0);

  if (overview.isLoading) {
    return (
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
        {Array.from({ length: 4 }).map((_, i) => (
          <CardSkeleton key={i} />
        ))}
      </div>
    );
  }

  if (overview.isError) {
    return <QueryError error={overview.error} onRetry={() => overview.refetch()} />;
  }

  const slowRows = Array.isArray(slow.data) ? (slow.data as Row[]) : [];

  return (
    <div className="space-y-6">
      {/* Top stats */}
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <StatCard
          label="Database size"
          value={String(ov.size ?? formatBytes(ov.size_bytes))}
          hint={String(ov.database_name ?? "current database")}
          icon={HardDrive}
          tone="brand"
        />
        <StatCard
          label="Cache hit ratio"
          value={formatPercent(cacheRatio)}
          hint={cacheRatio >= 99 ? "Excellent" : cacheRatio >= 90 ? "Healthy" : "Needs attention"}
          icon={Gauge}
          tone={cacheRatio >= 95 ? "teal" : cacheRatio >= 90 ? "amber" : "rose"}
        />
        <StatCard
          label="Connections"
          value={`${formatNumber(usedConn)}${maxConn ? ` / ${formatNumber(maxConn)}` : ""}`}
          hint={maxConn ? `${formatPercent((usedConn / maxConn) * 100, 0)} of max in use` : "in use"}
          icon={Users}
          tone="violet"
        />
        <StatCard
          label="Transactions"
          value={formatNumber(ov.commits)}
          hint={`${formatNumber(ov.rollbacks)} rollbacks`}
          icon={ArrowDownUp}
          tone="brand"
        />
      </div>

      {/* Activity mini stats */}
      <div className="grid grid-cols-2 gap-4 lg:grid-cols-4">
        <StatCard label="Active sessions" value={formatNumber(activeCount)} icon={Activity} tone="teal" hint="non-idle queries" />
        <StatCard label="Idle sessions" value={formatNumber(idleCount)} icon={Users} tone="neutral" hint="waiting connections" />
        <StatCard label="Locks held" value={formatNumber(lockCount)} icon={Lock} tone="amber" hint="across all sessions" />
        <StatCard
          label="Blocked queries"
          value={formatNumber(blockedCount)}
          icon={Zap}
          tone={blockedCount > 0 ? "rose" : "neutral"}
          hint={blockedCount > 0 ? "needs attention" : "none waiting"}
        />
      </div>

      {/* Charts row */}
      <div className="grid grid-cols-1 gap-4 lg:grid-cols-3">
        <Card>
          <CardHeader title="Buffer cache" subtitle="Hits vs disk reads" icon={<Gauge className="h-4 w-4" />} />
          <div className="card-pad pt-3">
            {ioData.some((d) => d.value > 0) ? (
              <>
                <DonutChart data={ioData} />
                <div className="mt-3 flex justify-center gap-5 text-xs">
                  <Legend color="#3358f4" label="Cache hits" value={formatNumber(ov.blocks_hit)} />
                  <Legend color="#8b5cf6" label="Disk reads" value={formatNumber(ov.blocks_read)} />
                </div>
              </>
            ) : (
              <EmptyState title="No I/O activity yet" />
            )}
          </div>
        </Card>

        <Card>
          <CardHeader title="Write workload" subtitle="Tuples since stats reset" icon={<Database className="h-4 w-4" />} />
          <div className="card-pad pt-3">
            {dmlData.length ? (
              <>
                <DonutChart data={dmlData} />
                <div className="mt-3 flex flex-wrap justify-center gap-4 text-xs">
                  {dmlData.map((d, i) => (
                    <Legend
                      key={d.name}
                      color={["#3358f4", "#8b5cf6", "#0fb6a8"][i]}
                      label={d.name}
                      value={formatNumber(d.value)}
                    />
                  ))}
                </div>
              </>
            ) : (
              <EmptyState title="No write activity yet" />
            )}
          </div>
        </Card>

        <Card>
          <CardHeader title="Throughput" subtitle="Rows processed" icon={<ArrowDownUp className="h-4 w-4" />} />
          <div className="card-pad space-y-3 pt-4">
            <MetricRow label="Rows returned" value={formatNumber(ov.rows_returned)} />
            <MetricRow label="Rows fetched" value={formatNumber(ov.rows_fetched)} />
            <MetricRow label="Temp files" value={formatNumber(ov.temp_files)} />
            <MetricRow label="Deadlocks" value={formatNumber(ov.deadlocks)} tone={toNumber(ov.deadlocks) > 0 ? "rose" : undefined} />
            <MetricRow label="Conflicts" value={formatNumber(ov.conflicts)} />
          </div>
        </Card>
      </div>

      {/* Slow queries preview */}
      <Card>
        <CardHeader
          title="Heaviest queries"
          subtitle="Ranked by total execution time"
          icon={<Zap className="h-4 w-4" />}
          action={<Badge tone="brand">Top {slowRows.length || 0}</Badge>}
        />
        <div className="mt-3">
          {slow.isLoading ? (
            <div className="px-5 pb-5 text-sm text-ink-muted">Loading…</div>
          ) : slowRows.length ? (
            <div className="divide-y divide-slate-100">
              {slowRows.map((q, i) => (
                <div key={i} className="flex items-start gap-4 px-5 py-3">
                  <span className="mt-0.5 grid h-6 w-6 shrink-0 place-items-center rounded-lg bg-surface-sunken text-xs font-semibold text-ink-muted">
                    {i + 1}
                  </span>
                  <code className="min-w-0 flex-1 truncate font-mono text-xs text-ink">
                    {truncate(compactQuery(q.query), 110)}
                  </code>
                  <div className="flex shrink-0 items-center gap-4 text-xs">
                    <span className="text-ink-muted">{formatNumber(q.calls)} calls</span>
                    <Badge tone="amber">{formatMs(q.total_time_ms)}</Badge>
                  </div>
                </div>
              ))}
            </div>
          ) : (
            <EmptyState
              title="No query statistics available"
              description="Enable the pg_stat_statements extension to surface your heaviest queries here."
            />
          )}
        </div>
      </Card>
    </div>
  );
}

function Legend({ color, label, value }: { color: string; label: string; value: string }) {
  return (
    <div className="flex items-center gap-1.5">
      <span className="h-2.5 w-2.5 rounded-full" style={{ background: color }} />
      <span className="text-ink-muted">{label}</span>
      <span className="font-medium text-ink">{value}</span>
    </div>
  );
}

function MetricRow({
  label,
  value,
  tone,
}: {
  label: string;
  value: string;
  tone?: "rose";
}) {
  return (
    <div className="flex items-center justify-between text-sm">
      <span className="text-ink-muted">{label}</span>
      <span className={tone === "rose" ? "font-semibold text-accent-rose" : "font-medium text-ink"}>
        {value}
      </span>
    </div>
  );
}
