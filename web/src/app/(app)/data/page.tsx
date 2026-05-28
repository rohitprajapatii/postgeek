"use client";

import { useMemo, useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { api, type Row, type SchemaInfo } from "@/lib/api";
import { Card, Badge, Button, EmptyState, Spinner } from "@/components/ui/primitives";
import { QueryError, TableSkeleton } from "@/components/ui/states";
import { cn } from "@/lib/utils";
import { formatNumber, truncate } from "@/lib/format";
import {
  ChevronRight,
  Columns3,
  Database,
  KeyRound,
  Link2,
  Search,
  Table2,
  Terminal,
} from "lucide-react";
import { QueryConsole } from "@/components/data/query-console";

type ViewTab = "data" | "structure" | "sql";

export default function DataStudioPage() {
  const [selected, setSelected] = useState<{ schema: string; table: string } | null>(null);
  const [tab, setTab] = useState<ViewTab>("data");

  return (
    <div className="grid grid-cols-1 gap-4 lg:grid-cols-[300px_1fr]">
      <SchemaBrowser selected={selected} onSelect={(s, t) => { setSelected({ schema: s, table: t }); setTab("data"); }} />

      <div className="min-w-0">
        {selected ? (
          <TableWorkspace key={`${selected.schema}.${selected.table}`} schema={selected.schema} table={selected.table} tab={tab} onTab={setTab} />
        ) : (
          <Card className="flex min-h-[60vh] items-center justify-center">
            <EmptyState
              icon={<Table2 className="h-6 w-6" />}
              title="Select a table to begin"
              description="Browse schemas on the left, then explore rows, inspect structure, or run SQL."
            />
          </Card>
        )}
      </div>
    </div>
  );
}

function SchemaBrowser({
  selected,
  onSelect,
}: {
  selected: { schema: string; table: string } | null;
  onSelect: (schema: string, table: string) => void;
}) {
  const [search, setSearch] = useState("");
  const { data, isLoading, isError, error, refetch } = useQuery({
    queryKey: ["schemas"],
    queryFn: api.schemas,
  });

  const schemas = (data?.data ?? []) as SchemaInfo[];
  const filtered = useMemo(() => {
    const q = search.toLowerCase().trim();
    if (!q) return schemas;
    return schemas
      .map((s) => ({
        ...s,
        tables: s.tables.filter(
          (t) => t.tableName.toLowerCase().includes(q) || s.schemaName.toLowerCase().includes(q),
        ),
      }))
      .filter((s) => s.tables.length > 0);
  }, [schemas, search]);

  return (
    <Card className="flex h-[calc(100vh-8rem)] flex-col">
      <div className="border-b border-slate-100 p-3">
        <div className="relative">
          <Search className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-slate-400" />
          <input
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Search tables…"
            className="h-9 w-full rounded-xl border border-slate-200 bg-surface-subtle pl-9 pr-3 text-sm outline-none transition-all focus:border-brand-400 focus:bg-white focus:ring-4 focus:ring-brand-400/10"
          />
        </div>
      </div>
      <div className="scrollbar-thin flex-1 overflow-y-auto p-2">
        {isLoading ? (
          <div className="flex justify-center py-10">
            <Spinner />
          </div>
        ) : isError ? (
          <QueryError error={error} onRetry={() => refetch()} />
        ) : filtered.length ? (
          filtered.map((schema) => (
            <SchemaGroup
              key={schema.schemaName}
              schema={schema}
              selected={selected}
              onSelect={onSelect}
              defaultOpen={filtered.length <= 3 || Boolean(search)}
            />
          ))
        ) : (
          <EmptyState icon={<Database className="h-5 w-5" />} title="No tables found" />
        )}
      </div>
    </Card>
  );
}

function SchemaGroup({
  schema,
  selected,
  onSelect,
  defaultOpen,
}: {
  schema: SchemaInfo;
  selected: { schema: string; table: string } | null;
  onSelect: (schema: string, table: string) => void;
  defaultOpen: boolean;
}) {
  const [open, setOpen] = useState(defaultOpen);
  return (
    <div className="mb-1">
      <button
        onClick={() => setOpen((o) => !o)}
        className="flex w-full items-center gap-2 rounded-lg px-2.5 py-2 text-left text-xs font-semibold uppercase tracking-wide text-ink-muted hover:bg-surface-sunken"
      >
        <ChevronRight className={cn("h-3.5 w-3.5 transition-transform", open && "rotate-90")} />
        <Database className="h-3.5 w-3.5" />
        <span className="truncate">{schema.schemaName}</span>
        <span className="ml-auto rounded-full bg-surface-sunken px-1.5 text-[10px] font-medium">
          {schema.tables.length}
        </span>
      </button>
      {open ? (
        <div className="ml-3 border-l border-slate-100 pl-1.5">
          {schema.tables.map((t) => {
            const active = selected?.schema === schema.schemaName && selected?.table === t.tableName;
            return (
              <button
                key={t.tableName}
                onClick={() => onSelect(schema.schemaName, t.tableName)}
                className={cn(
                  "flex w-full items-center gap-2 rounded-lg px-2.5 py-1.5 text-left text-sm transition-colors",
                  active ? "bg-brand-50 font-medium text-brand-700" : "text-ink hover:bg-surface-sunken",
                )}
              >
                <Table2 className={cn("h-3.5 w-3.5 shrink-0", active ? "text-brand-600" : "text-slate-400")} />
                <span className="truncate">{t.tableName}</span>
                <span className="ml-auto shrink-0 text-[10px] text-ink-muted">
                  {formatNumber(t.rowCount)}
                </span>
              </button>
            );
          })}
        </div>
      ) : null}
    </div>
  );
}

const workspaceTabs: { id: ViewTab; label: string; icon: typeof Table2 }[] = [
  { id: "data", label: "Data", icon: Table2 },
  { id: "structure", label: "Structure", icon: Columns3 },
  { id: "sql", label: "SQL", icon: Terminal },
];

function TableWorkspace({
  schema,
  table,
  tab,
  onTab,
}: {
  schema: string;
  table: string;
  tab: ViewTab;
  onTab: (t: ViewTab) => void;
}) {
  return (
    <div className="space-y-4">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div className="flex items-center gap-2">
          <Table2 className="h-5 w-5 text-brand-600" />
          <h2 className="text-lg font-semibold text-ink">
            <span className="text-ink-muted">{schema}.</span>
            {table}
          </h2>
        </div>
        <div className="flex gap-1 rounded-xl bg-white p-1 shadow-soft">
          {workspaceTabs.map((t) => {
            const Icon = t.icon;
            return (
              <button
                key={t.id}
                onClick={() => onTab(t.id)}
                className={cn(
                  "inline-flex items-center gap-1.5 rounded-lg px-3 py-1.5 text-sm font-medium transition-all",
                  tab === t.id ? "bg-brand-600 text-white shadow-soft" : "text-ink-muted hover:bg-surface-sunken hover:text-ink",
                )}
              >
                <Icon className="h-3.5 w-3.5" />
                {t.label}
              </button>
            );
          })}
        </div>
      </div>

      {tab === "data" ? (
        <TableData schema={schema} table={table} />
      ) : tab === "structure" ? (
        <TableStructure schema={schema} table={table} />
      ) : (
        <QueryConsole schema={schema} table={table} />
      )}
    </div>
  );
}

function TableData({ schema, table }: { schema: string; table: string }) {
  const [page, setPage] = useState(1);
  const limit = 50;
  const { data, isLoading, isError, error, refetch, isFetching } = useQuery({
    queryKey: ["tableData", schema, table, page],
    queryFn: () => api.tableData(schema, table, { page, limit }),
  });

  if (isLoading) return <Card><TableSkeleton rows={10} /></Card>;
  if (isError) return <Card><QueryError error={error} onRetry={() => refetch()} /></Card>;

  const rows = (data?.data ?? []) as Row[];
  const pagination = data?.pagination;
  const columns = rows.length ? Object.keys(rows[0]).filter((k) => !k.startsWith("_")) : [];

  return (
    <Card>
      <div className="scrollbar-thin max-h-[calc(100vh-15rem)] overflow-auto">
        {rows.length ? (
          <table className="w-full border-collapse text-sm">
            <thead className="sticky top-0 z-10 bg-white">
              <tr className="border-b border-slate-200">
                {columns.map((c) => (
                  <th key={c} className="whitespace-nowrap px-4 py-2.5 text-left text-xs font-semibold uppercase tracking-wide text-ink-muted">
                    {c}
                  </th>
                ))}
              </tr>
            </thead>
            <tbody>
              {rows.map((row, i) => (
                <tr key={i} className="border-b border-slate-100 last:border-0 hover:bg-surface-subtle">
                  {columns.map((c) => (
                    <td key={c} className="max-w-xs truncate px-4 py-2.5 align-middle">
                      <CellValue value={row[c]} />
                    </td>
                  ))}
                </tr>
              ))}
            </tbody>
          </table>
        ) : (
          <EmptyState icon={<Table2 className="h-5 w-5" />} title="This table is empty" />
        )}
      </div>

      {pagination ? (
        <div className="flex items-center justify-between border-t border-slate-100 px-4 py-3 text-sm">
          <span className="text-ink-muted">
            {formatNumber((pagination.page - 1) * pagination.limit + (rows.length ? 1 : 0))}–
            {formatNumber((pagination.page - 1) * pagination.limit + rows.length)} of{" "}
            {formatNumber(pagination.total)} rows
          </span>
          <div className="flex items-center gap-2">
            <Button variant="secondary" size="sm" disabled={page <= 1 || isFetching} onClick={() => setPage((p) => Math.max(1, p - 1))}>
              Previous
            </Button>
            <span className="text-xs text-ink-muted">
              Page {pagination.page} / {Math.max(1, pagination.totalPages)}
            </span>
            <Button variant="secondary" size="sm" disabled={page >= pagination.totalPages || isFetching} onClick={() => setPage((p) => p + 1)}>
              Next
            </Button>
          </div>
        </div>
      ) : null}
    </Card>
  );
}

function CellValue({ value }: { value: unknown }) {
  if (value === null || value === undefined)
    return <span className="text-xs italic text-slate-400">null</span>;
  if (typeof value === "boolean")
    return <Badge tone={value ? "teal" : "neutral"}>{String(value)}</Badge>;
  if (typeof value === "object")
    return <code className="font-mono text-xs text-violet-600">{truncate(JSON.stringify(value), 60)}</code>;
  return <span title={String(value)}>{truncate(String(value), 80)}</span>;
}

function TableStructure({ schema, table }: { schema: string; table: string }) {
  const { data, isLoading, isError, error, refetch } = useQuery({
    queryKey: ["tableInfo", schema, table],
    queryFn: () => api.tableInfo(schema, table),
  });

  if (isLoading) return <Card><TableSkeleton rows={8} /></Card>;
  if (isError) return <Card><QueryError error={error} onRetry={() => refetch()} /></Card>;

  const info = data?.data;
  if (!info) return null;

  return (
    <div className="space-y-4">
      <div className="grid grid-cols-2 gap-4 sm:grid-cols-4">
        <MiniStat label="Rows" value={formatNumber(info.rowCount)} />
        <MiniStat label="Columns" value={String(info.columns.length)} />
        <MiniStat label="Primary keys" value={String(info.primaryKeys.length)} />
        <MiniStat label="Indexes" value={String(info.indexes.length)} />
      </div>

      <Card>
        <table className="w-full border-collapse text-sm">
          <thead>
            <tr className="border-b border-slate-200">
              {["Column", "Type", "Nullable", "Default", "Key"].map((h) => (
                <th key={h} className="px-4 py-2.5 text-left text-xs font-semibold uppercase tracking-wide text-ink-muted">
                  {h}
                </th>
              ))}
            </tr>
          </thead>
          <tbody>
            {info.columns.map((col) => (
              <tr key={col.columnName} className="border-b border-slate-100 last:border-0 hover:bg-surface-subtle">
                <td className="px-4 py-2.5 font-medium text-ink">{col.columnName}</td>
                <td className="px-4 py-2.5">
                  <code className="font-mono text-xs text-violet-600">
                    {col.dataType}
                    {col.maxLength ? `(${col.maxLength})` : ""}
                  </code>
                </td>
                <td className="px-4 py-2.5">
                  {col.isNullable ? <span className="text-xs text-ink-muted">nullable</span> : <Badge tone="neutral">not null</Badge>}
                </td>
                <td className="px-4 py-2.5 text-xs text-ink-muted">{col.defaultValue ? truncate(col.defaultValue, 30) : "—"}</td>
                <td className="px-4 py-2.5">
                  <div className="flex gap-1">
                    {col.isPrimaryKey ? (
                      <Badge tone="amber"><KeyRound className="h-3 w-3" />PK</Badge>
                    ) : null}
                    {col.isForeignKey ? (
                      <Badge tone="brand"><Link2 className="h-3 w-3" />FK</Badge>
                    ) : null}
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </Card>

      {info.indexes.length ? (
        <Card className="card-pad">
          <h3 className="mb-3 text-sm font-semibold text-ink">Indexes</h3>
          <div className="space-y-2">
            {info.indexes.map((idx) => (
              <div key={idx.indexName} className="flex items-center justify-between rounded-xl bg-surface-subtle px-3.5 py-2.5">
                <code className="font-mono text-xs text-ink">{idx.indexName}</code>
                <div className="flex items-center gap-2">
                  <span className="text-xs text-ink-muted">{idx.columns.join(", ")}</span>
                  {idx.isPrimary ? <Badge tone="amber">primary</Badge> : idx.isUnique ? <Badge tone="teal">unique</Badge> : null}
                </div>
              </div>
            ))}
          </div>
        </Card>
      ) : null}
    </div>
  );
}

function MiniStat({ label, value }: { label: string; value: string }) {
  return (
    <Card className="card-pad">
      <p className="text-xs font-medium uppercase tracking-wide text-ink-muted">{label}</p>
      <p className="mt-1 text-xl font-semibold text-ink">{value}</p>
    </Card>
  );
}
