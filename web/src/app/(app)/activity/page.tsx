"use client";

import { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { api, type Row } from "@/lib/api";
import { Card, Badge, Button } from "@/components/ui/primitives";
import { DataTable, type Column } from "@/components/ui/data-table";
import { TableSkeleton, QueryError } from "@/components/ui/states";
import { cn } from "@/lib/utils";
import { compactQuery, formatDuration, truncate } from "@/lib/format";
import { Activity, Lock, Pause, RefreshCw, XCircle, Zap } from "lucide-react";

type Tab = "active" | "idle" | "locks" | "blocked";

const tabs: { id: Tab; label: string; icon: typeof Activity }[] = [
  { id: "active", label: "Active sessions", icon: Activity },
  { id: "idle", label: "Idle sessions", icon: Pause },
  { id: "locks", label: "Locks", icon: Lock },
  { id: "blocked", label: "Blocked", icon: Zap },
];

const queryFns: Record<Tab, () => Promise<Row[]>> = {
  active: api.activeSessions,
  idle: api.idleSessions,
  locks: api.locks,
  blocked: api.blockedQueries,
};

export default function ActivityPage() {
  const [tab, setTab] = useState<Tab>("active");
  const qc = useQueryClient();

  const { data, isLoading, isError, error, refetch, isFetching } = useQuery({
    queryKey: ["activity", tab],
    queryFn: queryFns[tab],
    refetchInterval: tab === "active" ? 8000 : false,
  });

  const terminate = useMutation({
    mutationFn: (pid: number) => api.terminateSession(pid),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["activity"] });
    },
  });

  const rows = (data ?? []) as Row[];

  // counts for badges
  const counts = useQueries();

  return (
    <div className="space-y-4">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div className="flex flex-wrap gap-1.5 rounded-xl bg-white p-1 shadow-soft">
          {tabs.map((t) => {
            const Icon = t.icon;
            const active = tab === t.id;
            const count = counts[t.id];
            return (
              <button
                key={t.id}
                onClick={() => setTab(t.id)}
                className={cn(
                  "inline-flex items-center gap-2 rounded-lg px-3.5 py-2 text-sm font-medium transition-all",
                  active
                    ? "bg-brand-600 text-white shadow-soft"
                    : "text-ink-muted hover:bg-surface-sunken hover:text-ink",
                )}
              >
                <Icon className="h-4 w-4" />
                {t.label}
                {count !== undefined ? (
                  <span
                    className={cn(
                      "rounded-full px-1.5 text-[11px] font-semibold",
                      active ? "bg-white/20" : "bg-surface-sunken",
                    )}
                  >
                    {count}
                  </span>
                ) : null}
              </button>
            );
          })}
        </div>
        <Button variant="secondary" size="sm" onClick={() => refetch()} loading={isFetching}>
          <RefreshCw className="h-3.5 w-3.5" />
          Refresh
        </Button>
      </div>

      <Card>
        {isLoading ? (
          <TableSkeleton />
        ) : isError ? (
          <QueryError error={error} onRetry={() => refetch()} />
        ) : tab === "active" ? (
          <ActiveTable rows={rows} onTerminate={(pid) => terminate.mutate(pid)} terminatingPid={terminate.variables} busy={terminate.isPending} />
        ) : tab === "idle" ? (
          <IdleTable rows={rows} onTerminate={(pid) => terminate.mutate(pid)} terminatingPid={terminate.variables} busy={terminate.isPending} />
        ) : tab === "locks" ? (
          <LocksTable rows={rows} />
        ) : (
          <BlockedTable rows={rows} />
        )}
      </Card>
    </div>
  );
}

function useQueries(): Partial<Record<Tab, number>> {
  const active = useQuery({ queryKey: ["activity", "active"], queryFn: api.activeSessions });
  const idle = useQuery({ queryKey: ["activity", "idle"], queryFn: api.idleSessions });
  const locks = useQuery({ queryKey: ["activity", "locks"], queryFn: api.locks });
  const blocked = useQuery({ queryKey: ["activity", "blocked"], queryFn: api.blockedQueries });
  return {
    active: active.data?.length,
    idle: idle.data?.length,
    locks: locks.data?.length,
    blocked: blocked.data?.length,
  };
}

function StateBadge({ state }: { state: unknown }) {
  const s = String(state ?? "");
  const tone =
    s === "active" ? "teal" : s.includes("idle in transaction") ? "amber" : s === "idle" ? "neutral" : "violet";
  return <Badge tone={tone as never}>{s || "—"}</Badge>;
}

function QueryCell({ value }: { value: unknown }) {
  return (
    <code className="block max-w-md truncate font-mono text-xs text-ink" title={String(value ?? "")}>
      {truncate(compactQuery(value), 90) || "—"}
    </code>
  );
}

function TerminateButton({ pid, onTerminate, busy, terminatingPid }: { pid: number; onTerminate: (pid: number) => void; busy: boolean; terminatingPid?: number }) {
  return (
    <Button
      variant="ghost"
      size="sm"
      className="text-accent-rose hover:bg-rose-50"
      loading={busy && terminatingPid === pid}
      onClick={() => {
        if (confirm(`Terminate backend PID ${pid}? This will cancel its work.`)) onTerminate(pid);
      }}
    >
      <XCircle className="h-3.5 w-3.5" />
      Kill
    </Button>
  );
}

function ActiveTable({ rows, onTerminate, busy, terminatingPid }: { rows: Row[]; onTerminate: (pid: number) => void; busy: boolean; terminatingPid?: number }) {
  const columns: Column<Row>[] = [
    { key: "pid", header: "PID", render: (r) => <span className="font-mono text-xs">{String(r.pid)}</span> },
    { key: "username", header: "User", render: (r) => String(r.username ?? "—") },
    { key: "application_name", header: "Application", render: (r) => truncate(r.application_name, 24) || "—" },
    { key: "state", header: "State", render: (r) => <StateBadge state={r.state} /> },
    { key: "wait_event", header: "Wait", render: (r) => (r.wait_event ? <Badge tone="amber">{String(r.wait_event)}</Badge> : "—") },
    { key: "query_duration_seconds", header: "Duration", align: "right", render: (r) => formatDuration(r.query_duration_seconds) },
    { key: "query", header: "Query", render: (r) => <QueryCell value={r.query} /> },
    { key: "actions", header: "", align: "right", render: (r) => <TerminateButton pid={Number(r.pid)} onTerminate={onTerminate} busy={busy} terminatingPid={terminatingPid} /> },
  ];
  return <DataTable columns={columns} rows={rows} rowKey={(r) => String(r.pid)} emptyLabel="No active sessions — the database is quiet." />;
}

function IdleTable({ rows, onTerminate, busy, terminatingPid }: { rows: Row[]; onTerminate: (pid: number) => void; busy: boolean; terminatingPid?: number }) {
  const columns: Column<Row>[] = [
    { key: "pid", header: "PID", render: (r) => <span className="font-mono text-xs">{String(r.pid)}</span> },
    { key: "username", header: "User", render: (r) => String(r.username ?? "—") },
    { key: "application_name", header: "Application", render: (r) => truncate(r.application_name, 24) || "—" },
    { key: "client_address", header: "Client", render: (r) => String(r.client_address ?? "—") },
    { key: "idle_duration_seconds", header: "Idle for", align: "right", render: (r) => formatDuration(r.idle_duration_seconds) },
    { key: "query", header: "Last query", render: (r) => <QueryCell value={r.query} /> },
    { key: "actions", header: "", align: "right", render: (r) => <TerminateButton pid={Number(r.pid)} onTerminate={onTerminate} busy={busy} terminatingPid={terminatingPid} /> },
  ];
  return <DataTable columns={columns} rows={rows} rowKey={(r) => String(r.pid)} emptyLabel="No idle sessions." />;
}

function LocksTable({ rows }: { rows: Row[] }) {
  const columns: Column<Row>[] = [
    { key: "pid", header: "PID", render: (r) => <span className="font-mono text-xs">{String(r.pid)}</span> },
    { key: "locktype", header: "Type", render: (r) => String(r.locktype ?? "—") },
    { key: "mode", header: "Mode", render: (r) => <Badge tone="violet">{String(r.mode ?? "—")}</Badge> },
    { key: "relation_name", header: "Relation", render: (r) => String(r.relation_name ?? "—") },
    { key: "granted", header: "Granted", render: (r) => (r.granted ? <Badge tone="teal">granted</Badge> : <Badge tone="rose">waiting</Badge>) },
    { key: "username", header: "User", render: (r) => String(r.username ?? "—") },
    { key: "query", header: "Query", render: (r) => <QueryCell value={r.query} /> },
  ];
  return <DataTable columns={columns} rows={rows} rowKey={(r, i) => `${r.pid}-${i}`} emptyLabel="No locks currently held." />;
}

function BlockedTable({ rows }: { rows: Row[] }) {
  const columns: Column<Row>[] = [
    { key: "blocked_pid", header: "Blocked PID", render: (r) => <span className="font-mono text-xs text-accent-rose">{String(r.blocked_pid)}</span> },
    { key: "blocked_user", header: "Blocked user", render: (r) => String(r.blocked_user ?? "—") },
    { key: "blocked_duration_seconds", header: "Waiting", align: "right", render: (r) => formatDuration(r.blocked_duration_seconds) },
    { key: "blocking_pid", header: "Blocking PID", render: (r) => <span className="font-mono text-xs text-brand-600">{String(r.blocking_pid)}</span> },
    { key: "blocking_user", header: "Blocking user", render: (r) => String(r.blocking_user ?? "—") },
    { key: "blocked_query", header: "Blocked query", render: (r) => <QueryCell value={r.blocked_query} /> },
  ];
  return (
    <DataTable
      columns={columns}
      rows={rows}
      rowKey={(r, i) => `${r.blocked_pid}-${i}`}
      emptyLabel="No blocked queries — no lock contention detected."
    />
  );
}
