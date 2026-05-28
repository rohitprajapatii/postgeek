"use client";

import { useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { api, type Row } from "@/lib/api";
import { Card, CardHeader, Badge } from "@/components/ui/primitives";
import { DataTable, type Column } from "@/components/ui/data-table";
import { TableSkeleton, QueryError } from "@/components/ui/states";
import { StatCard } from "@/components/ui/stat-card";
import { cn } from "@/lib/utils";
import { formatNumber, formatPercent, toNumber } from "@/lib/format";
import { BarChart3, Database, HardDrive, Layers, Gauge, Timer } from "lucide-react";

type Tab = "tables" | "indexes" | "io" | "checkpoints";

const tabs: { id: Tab; label: string; icon: typeof Database }[] = [
  { id: "tables", label: "Tables", icon: Database },
  { id: "indexes", label: "Indexes", icon: Layers },
  { id: "io", label: "I/O", icon: HardDrive },
  { id: "checkpoints", label: "Checkpoints", icon: Timer },
];

function TableName({ schema, table }: { schema: unknown; table: unknown }) {
  return (
    <span className="font-medium text-ink">
      <span className="text-ink-muted">{String(schema)}.</span>
      {String(table)}
    </span>
  );
}

function RatioBadge({ value }: { value: number }) {
  const tone = value >= 95 ? "teal" : value >= 80 ? "amber" : "rose";
  return <Badge tone={tone as never}>{value.toFixed(1)}%</Badge>;
}

export default function StatisticsPage() {
  const [tab, setTab] = useState<Tab>("tables");

  const tables = useQuery({ queryKey: ["statTables"], queryFn: api.tableStats, enabled: tab === "tables" });
  const indexes = useQuery({ queryKey: ["statIndexes"], queryFn: api.indexStats, enabled: tab === "indexes" });
  const io = useQuery({ queryKey: ["statIo"], queryFn: api.ioStats, enabled: tab === "io" });
  const bg = useQuery({ queryKey: ["statBg"], queryFn: api.bgWriterStats, enabled: tab === "checkpoints" });

  return (
    <div className="space-y-4">
      <div className="flex flex-wrap gap-1.5 rounded-xl bg-white p-1 shadow-soft">
        {tabs.map((t) => {
          const Icon = t.icon;
          const active = tab === t.id;
          return (
            <button
              key={t.id}
              onClick={() => setTab(t.id)}
              className={cn(
                "inline-flex items-center gap-2 rounded-lg px-3.5 py-2 text-sm font-medium transition-all",
                active ? "bg-brand-600 text-white shadow-soft" : "text-ink-muted hover:bg-surface-sunken hover:text-ink",
              )}
            >
              <Icon className="h-4 w-4" />
              {t.label}
            </button>
          );
        })}
      </div>

      {tab === "tables" ? (
        <Card>
          <CardHeader title="Table statistics" subtitle="Largest tables by total size" icon={<Database className="h-4 w-4" />} />
          <div className="mt-3">
            {tables.isLoading ? (
              <TableSkeleton />
            ) : tables.isError ? (
              <QueryError error={tables.error} onRetry={() => tables.refetch()} />
            ) : (
              <DataTable
                rows={(tables.data ?? []) as Row[]}
                rowKey={(r, i) => `${r.table_name}-${i}`}
                columns={
                  [
                    { key: "table_name", header: "Table", render: (r) => <TableName schema={r.schema} table={r.table_name} /> },
                    { key: "total_size", header: "Total", align: "right", render: (r) => <Badge tone="brand">{String(r.total_size)}</Badge> },
                    { key: "index_size", header: "Indexes", align: "right", render: (r) => String(r.index_size) },
                    { key: "live_rows", header: "Live rows", align: "right", render: (r) => formatNumber(r.live_rows) },
                    { key: "dead_rows", header: "Dead", align: "right", render: (r) => formatNumber(r.dead_rows) },
                    { key: "index_scan_ratio", header: "Index scan %", align: "right", render: (r) => <RatioBadge value={toNumber(r.index_scan_ratio)} /> },
                    { key: "sequential_scans", header: "Seq scans", align: "right", render: (r) => formatNumber(r.sequential_scans) },
                  ] as Column<Row>[]
                }
              />
            )}
          </div>
        </Card>
      ) : null}

      {tab === "indexes" ? (
        <Card>
          <CardHeader title="Index statistics" subtitle="Largest indexes and their usage" icon={<Layers className="h-4 w-4" />} />
          <div className="mt-3">
            {indexes.isLoading ? (
              <TableSkeleton />
            ) : indexes.isError ? (
              <QueryError error={indexes.error} onRetry={() => indexes.refetch()} />
            ) : (
              <DataTable
                rows={(indexes.data ?? []) as Row[]}
                rowKey={(r, i) => `${r.index_name}-${i}`}
                columns={
                  [
                    { key: "index_name", header: "Index", render: (r) => <code className="font-mono text-xs">{String(r.index_name)}</code> },
                    { key: "table_name", header: "Table", render: (r) => String(r.table_name) },
                    { key: "index_size", header: "Size", align: "right", render: (r) => <Badge tone="brand">{String(r.index_size)}</Badge> },
                    { key: "scans", header: "Scans", align: "right", render: (r) => formatNumber(r.scans) },
                    { key: "tuples_read", header: "Tuples read", align: "right", render: (r) => formatNumber(r.tuples_read) },
                    { key: "avg_tuples_per_scan", header: "Avg/scan", align: "right", render: (r) => formatNumber(r.avg_tuples_per_scan) },
                  ] as Column<Row>[]
                }
              />
            )}
          </div>
        </Card>
      ) : null}

      {tab === "io" ? (
        <Card>
          <CardHeader title="I/O statistics" subtitle="Buffer cache hit ratios per table" icon={<HardDrive className="h-4 w-4" />} />
          <div className="mt-3">
            {io.isLoading ? (
              <TableSkeleton />
            ) : io.isError ? (
              <QueryError error={io.error} onRetry={() => io.refetch()} />
            ) : (
              <DataTable
                rows={(io.data ?? []) as Row[]}
                rowKey={(r, i) => `${r.table_name}-${i}`}
                columns={
                  [
                    { key: "table_name", header: "Table", render: (r) => <TableName schema={r.schema} table={r.table_name} /> },
                    { key: "heap_blocks_hit", header: "Heap hits", align: "right", render: (r) => formatNumber(r.heap_blocks_hit) },
                    { key: "heap_blocks_read", header: "Heap reads", align: "right", render: (r) => formatNumber(r.heap_blocks_read) },
                    { key: "heap_hit_ratio", header: "Heap hit %", align: "right", render: (r) => <RatioBadge value={toNumber(r.heap_hit_ratio)} /> },
                    { key: "index_hit_ratio", header: "Index hit %", align: "right", render: (r) => <RatioBadge value={toNumber(r.index_hit_ratio)} /> },
                  ] as Column<Row>[]
                }
              />
            )}
          </div>
        </Card>
      ) : null}

      {tab === "checkpoints" ? (
        bg.isLoading ? (
          <Card><TableSkeleton rows={4} /></Card>
        ) : bg.isError ? (
          <Card><QueryError error={bg.error} onRetry={() => bg.refetch()} /></Card>
        ) : (
          <CheckpointStats data={(bg.data ?? {}) as Row} />
        )
      ) : null}
    </div>
  );
}

function CheckpointStats({ data }: { data: Row }) {
  const timed = toNumber(data.checkpoints_timed);
  const requested = toNumber(data.checkpoints_requested);
  const total = timed + requested;
  return (
    <div className="space-y-4">
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <StatCard label="Timed checkpoints" value={formatNumber(timed)} icon={Timer} tone="teal" hint={total ? formatPercent((timed / total) * 100, 0) + " of total" : undefined} />
        <StatCard label="Requested checkpoints" value={formatNumber(requested)} icon={Gauge} tone={requested > timed ? "amber" : "brand"} hint="forced by load" />
        <StatCard label="Buffers allocated" value={formatNumber(data.buffers_allocated)} icon={Layers} tone="violet" />
        <StatCard label="Backend buffers" value={formatNumber(data.buffers_written_backend)} icon={HardDrive} tone="brand" hint="written by backends" />
      </div>
      <Card className="card-pad">
        <h3 className="mb-3 flex items-center gap-2 text-sm font-semibold text-ink">
          <BarChart3 className="h-4 w-4 text-brand-600" /> Background writer detail
        </h3>
        <div className="grid grid-cols-2 gap-x-8 gap-y-2.5 text-sm sm:grid-cols-3">
          <Detail label="Checkpoint write time" value={`${formatNumber(data.checkpoint_write_time_ms)} ms`} />
          <Detail label="Checkpoint sync time" value={`${formatNumber(data.checkpoint_sync_time_ms)} ms`} />
          <Detail label="Buffers (checkpoint)" value={formatNumber(data.buffers_written_checkpoint)} />
          <Detail label="Buffers (bgwriter)" value={formatNumber(data.buffers_written_bgwriter)} />
          <Detail label="Max written / clean" value={formatNumber(data.bgwriter_maxwritten_count)} />
          <Detail label="Backend fsync" value={formatNumber(data.buffers_fsync_backend)} />
        </div>
      </Card>
    </div>
  );
}

function Detail({ label, value }: { label: string; value: string }) {
  return (
    <div className="flex items-center justify-between border-b border-slate-100 pb-2">
      <span className="text-ink-muted">{label}</span>
      <span className="font-medium text-ink">{value}</span>
    </div>
  );
}
