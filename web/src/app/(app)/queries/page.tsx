"use client";

import { useMemo, useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { api, type PlanNode, type Row } from "@/lib/api";
import { analyzeQueryStats, buildExplainSql, isExplainable } from "@/lib/advisor";
import { FindingsList, SeveritySummary } from "@/components/data/findings";
import { PlanViewer } from "@/components/data/plan-viewer";
import { StatCard } from "@/components/ui/stat-card";
import { Card, CardHeader, Badge, Button, EmptyState } from "@/components/ui/primitives";
import { CardSkeleton, QueryError, TableSkeleton } from "@/components/ui/states";
import { MiniBarChart, CHART_COLORS } from "@/components/charts/charts";
import {
  compactQuery,
  formatMs,
  formatNumber,
  formatPercent,
  toNumber,
  truncate,
} from "@/lib/format";
import { AlertCircle, ChevronDown, Database, Gauge, GitBranch, Hash, RotateCcw, Sparkles, Timer } from "lucide-react";
import { cn } from "@/lib/utils";

function hasError(data: unknown): data is { error: string; hint?: string } {
  return Boolean(data && typeof data === "object" && "error" in data);
}

export default function QueriesPage() {
  const qc = useQueryClient();
  const stats = useQuery({ queryKey: ["queryStats"], queryFn: api.queryStats });
  const types = useQuery({ queryKey: ["queryTypes"], queryFn: api.queryTypes });
  const slow = useQuery({ queryKey: ["slowQueries"], queryFn: () => api.slowQueries(20) });

  const reset = useMutation({
    mutationFn: api.resetQueryStats,
    onSuccess: () => qc.invalidateQueries(),
  });

  const enableExt = useMutation({
    mutationFn: api.enablePgStatStatements,
    onSuccess: (res) => {
      if (res?.success) qc.invalidateQueries();
    },
  });

  const st = (stats.data ?? {}) as Row;
  const extensionMissing =
    hasError(slow.data) || (st.message && String(st.message).includes("not available"));

  const typeRows = Array.isArray(types.data) ? (types.data as Row[]) : [];
  const typeChart = typeRows
    .filter((t) => !t.message)
    .map((t) => ({ name: String(t.query_type), value: toNumber(t.total_time_ms) }));

  const slowRows = Array.isArray(slow.data) ? (slow.data as Row[]) : [];

  return (
    <div className="space-y-6">
      {extensionMissing ? (
        <div className="rounded-2xl border border-amber-200 bg-amber-50 px-4 py-3.5">
          <div className="flex flex-wrap items-start justify-between gap-3">
            <div className="flex items-start gap-3">
              <AlertCircle className="mt-0.5 h-5 w-5 shrink-0 text-amber-600" />
              <div className="text-sm">
                <p className="font-medium text-amber-900">pg_stat_statements is not enabled</p>
                <p className="mt-0.5 text-amber-800">
                  Enable the extension to unlock detailed query performance metrics. This
                  requires superuser privileges.
                </p>
              </div>
            </div>
            <Button
              size="sm"
              className="bg-amber-600 hover:bg-amber-700"
              loading={enableExt.isPending}
              onClick={() => enableExt.mutate()}
            >
              <Sparkles className="h-3.5 w-3.5" />
              Enable extension
            </Button>
          </div>
          {enableExt.data?.error ? (
            <div className="mt-3 rounded-xl bg-amber-100/70 px-3 py-2 text-xs text-amber-900">
              {enableExt.data.error}
              {enableExt.data.hint ? <span className="block opacity-80">{enableExt.data.hint}</span> : null}
            </div>
          ) : null}
          {enableExt.data?.success ? (
            <div className="mt-3 rounded-xl bg-teal-100/70 px-3 py-2 text-xs text-teal-800">
              {enableExt.data.message}
            </div>
          ) : null}
        </div>
      ) : null}

      {/* Stats */}
      {stats.isLoading ? (
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
          {Array.from({ length: 4 }).map((_, i) => (
            <CardSkeleton key={i} />
          ))}
        </div>
      ) : (
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
          <StatCard label="Total calls" value={formatNumber(st.total_calls)} icon={Hash} tone="brand" hint="across tracked statements" />
          <StatCard label="Total exec time" value={formatMs(st.total_exec_time_ms)} icon={Timer} tone="violet" />
          <StatCard label="Avg query time" value={formatMs(st.avg_query_time_ms)} icon={Gauge} tone="teal" hint="mean per call" />
          <StatCard label="Cache hit ratio" value={formatPercent(st.cache_hit_ratio)} icon={Database} tone="amber" />
        </div>
      )}

      <div className="grid grid-cols-1 gap-4 lg:grid-cols-5">
        {/* Type distribution */}
        <Card className="lg:col-span-2">
          <CardHeader title="Time by query type" subtitle="Where execution time goes" icon={<Database className="h-4 w-4" />} />
          <div className="card-pad pt-2">
            {types.isLoading ? (
              <div className="h-[220px] animate-pulse rounded-xl bg-surface-sunken" />
            ) : typeChart.length ? (
              <>
                <MiniBarChart data={typeChart} color={CHART_COLORS[1]} />
                <div className="mt-3 space-y-1.5">
                  {typeRows
                    .filter((t) => !t.message)
                    .map((t) => (
                      <div key={String(t.query_type)} className="flex items-center justify-between text-xs">
                        <span className="font-medium text-ink">{String(t.query_type)}</span>
                        <span className="text-ink-muted">
                          {formatNumber(t.total_calls)} calls · {formatMs(t.total_time_ms)}
                        </span>
                      </div>
                    ))}
                </div>
              </>
            ) : (
              <EmptyState title="No query type data" />
            )}
          </div>
        </Card>

        {/* Slow queries */}
        <Card className="lg:col-span-3">
          <CardHeader
            title="Slowest queries"
            subtitle="Ranked by cumulative execution time"
            icon={<Timer className="h-4 w-4" />}
            action={
              <Button
                variant="secondary"
                size="sm"
                onClick={() => {
                  if (confirm("Reset all pg_stat_statements counters?")) reset.mutate();
                }}
                loading={reset.isPending}
              >
                <RotateCcw className="h-3.5 w-3.5" />
                Reset stats
              </Button>
            }
          />
          <div className="mt-3">
            {slow.isLoading ? (
              <TableSkeleton />
            ) : slow.isError ? (
              <QueryError error={slow.error} onRetry={() => slow.refetch()} />
            ) : slowRows.length ? (
              <div className="divide-y divide-slate-100">
                {slowRows.map((q, i) => (
                  <SlowQueryRow
                    key={i}
                    row={q}
                    rank={i + 1}
                    totalExecTimeMs={toNumber(st.total_exec_time_ms)}
                  />
                ))}
              </div>
            ) : (
              <EmptyState
                title="No slow queries recorded"
                description="Once queries run, the heaviest will appear here."
              />
            )}
          </div>
        </Card>
      </div>
    </div>
  );
}

function SlowQueryRow({
  row,
  rank,
  totalExecTimeMs,
}: {
  row: Row;
  rank: number;
  totalExecTimeMs: number;
}) {
  const [open, setOpen] = useState(false);
  const sql = compactQuery(row.query);

  const findings = useMemo(
    () => analyzeQueryStats(row, { totalExecTimeMs }),
    [row, totalExecTimeMs],
  );

  const explain = useMutation({
    mutationFn: async () => {
      const built = buildExplainSql(sql);
      const res = await api.executeQuery(built.sql, true);
      const raw = res.data.rows[0]?.["QUERY PLAN"] as Array<{ Plan: PlanNode }> | undefined;
      if (!raw?.[0]?.Plan) throw new Error("Could not parse the query plan");
      return { plan: raw[0].Plan, analyzed: built.analyzed, generic: built.generic };
    },
  });

  const explainable = isExplainable(sql);
  const explainError =
    explain.error instanceof Error ? explain.error.message : null;

  return (
    <div className="px-5 py-3">
      <button onClick={() => setOpen((o) => !o)} className="flex w-full items-start gap-3 text-left">
        <span className="mt-0.5 grid h-6 w-6 shrink-0 place-items-center rounded-lg bg-surface-sunken text-xs font-semibold text-ink-muted">
          {rank}
        </span>
        <code className="min-w-0 flex-1 font-mono text-xs text-ink">
          {open ? sql : truncate(sql, 120)}
        </code>
        <div className="flex shrink-0 items-center gap-2">
          <SeveritySummary findings={findings} />
          <Badge tone="amber">{formatMs(row.total_time_ms)}</Badge>
          <ChevronDown className={cn("h-4 w-4 text-slate-400 transition-transform", open && "rotate-180")} />
        </div>
      </button>

      {open ? (
        <div className="mt-3 space-y-4 pl-9">
          <div className="grid grid-cols-2 gap-x-6 gap-y-2 text-xs sm:grid-cols-4">
            <Metric label="Calls" value={formatNumber(row.calls)} />
            <Metric label="Mean" value={formatMs(row.avg_time_ms)} />
            <Metric label="Min" value={formatMs(row.min_time_ms)} />
            <Metric label="Max" value={formatMs(row.max_time_ms)} />
            <Metric label="Rows" value={formatNumber(row.rows)} />
            <Metric label="Shared hit" value={formatNumber(row.shared_blks_hit)} />
            <Metric label="Shared read" value={formatNumber(row.shared_blks_read)} />
            <Metric label="Stddev" value={formatMs(row.stddev_time_ms)} />
          </div>

          <div>
            <div className="mb-2 flex flex-wrap items-center justify-between gap-2">
              <h4 className="text-xs font-semibold uppercase tracking-wide text-ink-muted">
                Analysis
              </h4>
              {explainable ? (
                <Button
                  variant="secondary"
                  size="sm"
                  loading={explain.isPending}
                  onClick={() => explain.mutate()}
                >
                  <GitBranch className="h-3.5 w-3.5" />
                  {explain.data ? "Re-run plan" : "Explain"}
                </Button>
              ) : (
                <span className="text-[11px] text-ink-muted">
                  Plan unavailable for non-SELECT statements
                </span>
              )}
            </div>
            <FindingsList findings={findings} />
          </div>

          {explainError ? (
            <div className="rounded-xl border border-rose-200 bg-rose-50 px-3 py-2 text-xs text-rose-700">
              <span className="font-mono">{explainError}</span>
            </div>
          ) : null}

          {explain.data ? (
            <div>
              <div className="mb-2 flex items-center gap-2">
                <h4 className="text-xs font-semibold uppercase tracking-wide text-ink-muted">
                  Query plan
                </h4>
                {explain.data.generic ? (
                  <Badge tone="violet">generic plan</Badge>
                ) : null}
              </div>
              {explain.data.generic ? (
                <p className="mb-2 text-[11px] text-ink-muted">
                  This statement is stored with normalised parameters ($1, $2), so the
                  plan is generated without real values and has no runtime timings.
                </p>
              ) : null}
              <PlanViewer plan={explain.data.plan} analyzed={explain.data.analyzed} />
            </div>
          ) : null}
        </div>
      ) : null}
    </div>
  );
}

function Metric({ label, value }: { label: string; value: string }) {
  return (
    <div>
      <p className="text-ink-muted">{label}</p>
      <p className="font-medium text-ink">{value}</p>
    </div>
  );
}
