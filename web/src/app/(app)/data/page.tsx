"use client";

import { useMemo, useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { api, type Filter, type Row, type SchemaInfo, type TableInfo } from "@/lib/api";
import { Card, Badge, Button, EmptyState, Spinner } from "@/components/ui/primitives";
import { QueryError, TableSkeleton } from "@/components/ui/states";
import { Drawer } from "@/components/ui/modal";
import { cn } from "@/lib/utils";
import { formatNumber, truncate } from "@/lib/format";
import {
  ArrowDown,
  ArrowUp,
  ChevronRight,
  ChevronsUpDown,
  Columns3,
  Database,
  Download,
  Filter as FilterIcon,
  KeyRound,
  Link2,
  Pencil,
  Plus,
  Search,
  Table2,
  Terminal,
  Trash2,
  X,
} from "lucide-react";
import { QueryConsole } from "@/components/data/query-console";
import { RecordForm } from "@/components/data/record-form";

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

const OPERATORS = ["=", "!=", ">", "<", ">=", "<=", "ILIKE", "LIKE", "IN"];

function TableData({ schema, table }: { schema: string; table: string }) {
  const qc = useQueryClient();
  const limit = 50;
  const [page, setPage] = useState(1);
  const [sort, setSort] = useState<{ column: string; order: "ASC" | "DESC" } | null>(null);
  const [filters, setFilters] = useState<Filter[]>([]);
  const [showFilters, setShowFilters] = useState(false);
  const [editing, setEditing] = useState<{ mode: "create" | "edit"; row?: Row } | null>(null);
  const [related, setRelated] = useState<{ title: string; records: Row[] } | null>(null);

  const info = useQuery({
    queryKey: ["tableInfo", schema, table],
    queryFn: () => api.tableInfo(schema, table),
  });
  const tableInfo = info.data?.data as TableInfo | undefined;
  const primaryKeys = tableInfo?.primaryKeys ?? [];

  const { data, isLoading, isError, error, refetch, isFetching } = useQuery({
    queryKey: ["tableData", schema, table, page, sort, filters],
    queryFn: () =>
      api.tableData(schema, table, {
        page,
        limit,
        sortBy: sort?.column,
        sortOrder: sort?.order,
        filters,
      }),
  });

  const del = useMutation({
    mutationFn: (where: Row) => api.deleteRecord(schema, table, where),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["tableData", schema, table] }),
  });

  const toggleSort = (col: string) => {
    setPage(1);
    setSort((s) =>
      s?.column !== col
        ? { column: col, order: "ASC" }
        : s.order === "ASC"
          ? { column: col, order: "DESC" }
          : null,
    );
  };

  const whereFor = (row: Row): Row | null => {
    const keys = primaryKeys.length ? primaryKeys : null;
    if (!keys) return null;
    const where: Row = {};
    keys.forEach((k) => (where[k] = row[k]));
    return where;
  };

  const handleExport = async (format: "csv" | "json") => {
    const res = await api.exportTable(schema, table, format, filters);
    const blob = new Blob([res.data], {
      type: format === "csv" ? "text/csv" : "application/json",
    });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = res.filename;
    a.click();
    URL.revokeObjectURL(url);
  };

  const rows = (data?.data ?? []) as Row[];
  const pagination = data?.pagination;
  const columns = useMemo(
    () =>
      tableInfo?.columns.map((c) => c.columnName) ??
      (rows.length ? Object.keys(rows[0]).filter((k) => !k.startsWith("_")) : []),
    [tableInfo, rows],
  );
  const canEdit = primaryKeys.length > 0;

  return (
    <div className="space-y-3">
      {/* Toolbar */}
      <div className="flex flex-wrap items-center justify-between gap-2">
        <div className="flex items-center gap-2">
          <Button size="sm" onClick={() => setEditing({ mode: "create" })} disabled={!tableInfo}>
            <Plus className="h-3.5 w-3.5" />
            Add row
          </Button>
          <Button
            variant={filters.length || showFilters ? "primary" : "secondary"}
            size="sm"
            onClick={() => setShowFilters((s) => !s)}
          >
            <FilterIcon className="h-3.5 w-3.5" />
            Filter{filters.length ? ` (${filters.length})` : ""}
          </Button>
        </div>
        <div className="flex items-center gap-2">
          <Button variant="secondary" size="sm" onClick={() => handleExport("csv")}>
            <Download className="h-3.5 w-3.5" />
            CSV
          </Button>
          <Button variant="secondary" size="sm" onClick={() => handleExport("json")}>
            <Download className="h-3.5 w-3.5" />
            JSON
          </Button>
        </div>
      </div>

      {showFilters ? (
        <FilterBar
          columns={columns}
          filters={filters}
          onApply={(f) => {
            setFilters(f);
            setPage(1);
          }}
        />
      ) : null}

      <Card>
        {isLoading ? (
          <TableSkeleton rows={10} />
        ) : isError ? (
          <QueryError error={error} onRetry={() => refetch()} />
        ) : (
          <>
            <div className="scrollbar-thin max-h-[calc(100vh-19rem)] overflow-auto">
              {rows.length ? (
                <table className="w-full border-collapse text-sm">
                  <thead className="sticky top-0 z-10 bg-white">
                    <tr className="border-b border-slate-200">
                      {columns.map((c) => {
                        const active = sort?.column === c;
                        return (
                          <th key={c} className="whitespace-nowrap px-4 py-2.5 text-left">
                            <button
                              onClick={() => toggleSort(c)}
                              className="inline-flex items-center gap-1 text-xs font-semibold uppercase tracking-wide text-ink-muted hover:text-ink"
                            >
                              {c}
                              {active ? (
                                sort!.order === "ASC" ? (
                                  <ArrowUp className="h-3 w-3 text-brand-600" />
                                ) : (
                                  <ArrowDown className="h-3 w-3 text-brand-600" />
                                )
                              ) : (
                                <ChevronsUpDown className="h-3 w-3 text-slate-300" />
                              )}
                            </button>
                          </th>
                        );
                      })}
                      {canEdit ? <th className="px-4 py-2.5" /> : null}
                    </tr>
                  </thead>
                  <tbody>
                    {rows.map((row, i) => {
                      const relations = (row._relations ?? {}) as Record<string, { relatedRecords: Row[]; referencedTable: string }>;
                      return (
                        <tr key={i} className="group border-b border-slate-100 last:border-0 hover:bg-surface-subtle">
                          {columns.map((c) => (
                            <td key={c} className="max-w-xs truncate px-4 py-2.5 align-middle">
                              <CellValue
                                value={row[c]}
                                relation={relations[c]}
                                onOpenRelation={(rec, label) => setRelated({ title: label, records: rec })}
                              />
                            </td>
                          ))}
                          {canEdit ? (
                            <td className="px-2 py-2 text-right">
                              <div className="flex justify-end gap-0.5 opacity-0 transition-opacity group-hover:opacity-100">
                                <button
                                  onClick={() => setEditing({ mode: "edit", row })}
                                  className="grid h-7 w-7 place-items-center rounded-lg text-ink-muted hover:bg-brand-50 hover:text-brand-600"
                                  title="Edit row"
                                >
                                  <Pencil className="h-3.5 w-3.5" />
                                </button>
                                <button
                                  onClick={() => {
                                    const where = whereFor(row);
                                    if (where && confirm("Delete this row? This cannot be undone.")) del.mutate(where);
                                  }}
                                  className="grid h-7 w-7 place-items-center rounded-lg text-ink-muted hover:bg-rose-50 hover:text-accent-rose"
                                  title="Delete row"
                                >
                                  <Trash2 className="h-3.5 w-3.5" />
                                </button>
                              </div>
                            </td>
                          ) : null}
                        </tr>
                      );
                    })}
                  </tbody>
                </table>
              ) : (
                <EmptyState
                  icon={<Table2 className="h-5 w-5" />}
                  title={filters.length ? "No rows match your filters" : "This table is empty"}
                />
              )}
            </div>

            {pagination ? (
              <div className="flex items-center justify-between border-t border-slate-100 px-4 py-3 text-sm">
                <span className="text-ink-muted">
                  {formatNumber((pagination.page - 1) * pagination.limit + (rows.length ? 1 : 0))}–
                  {formatNumber((pagination.page - 1) * pagination.limit + rows.length)} of{" "}
                  {formatNumber(pagination.total)} rows
                  {!canEdit ? " · no primary key (read-only)" : ""}
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
          </>
        )}
      </Card>

      {editing && tableInfo ? (
        <RecordForm
          schema={schema}
          table={table}
          info={tableInfo}
          mode={editing.mode}
          initial={editing.row}
          onClose={() => setEditing(null)}
          onSaved={() => {
            setEditing(null);
            qc.invalidateQueries({ queryKey: ["tableData", schema, table] });
          }}
        />
      ) : null}

      {related ? (
        <Drawer open onClose={() => setRelated(null)} title="Related record" subtitle={related.title}>
          {related.records.length ? (
            related.records.map((rec, i) => (
              <div key={i} className="mb-3 space-y-1.5 rounded-xl border border-slate-200 p-3 last:mb-0">
                {Object.entries(rec)
                  .filter(([k]) => !k.startsWith("_"))
                  .map(([k, v]) => (
                    <div key={k} className="flex items-start justify-between gap-4 text-sm">
                      <span className="text-ink-muted">{k}</span>
                      <span className="text-right font-medium text-ink">
                        <CellValue value={v} />
                      </span>
                    </div>
                  ))}
              </div>
            ))
          ) : (
            <EmptyState title="No related record found" />
          )}
        </Drawer>
      ) : null}
    </div>
  );
}

function FilterBar({
  columns,
  filters,
  onApply,
}: {
  columns: string[];
  filters: Filter[];
  onApply: (f: Filter[]) => void;
}) {
  const [draft, setDraft] = useState<Filter[]>(filters.length ? filters : [{ column: columns[0] ?? "", operator: "=", value: "" }]);

  const update = (i: number, patch: Partial<Filter>) =>
    setDraft((d) => d.map((f, idx) => (idx === i ? { ...f, ...patch } : f)));

  return (
    <Card className="card-pad space-y-2.5">
      {draft.map((f, i) => (
        <div key={i} className="flex flex-wrap items-center gap-2">
          <select
            value={f.column}
            onChange={(e) => update(i, { column: e.target.value })}
            className="h-9 rounded-lg border border-slate-200 bg-surface-subtle px-2.5 text-sm outline-none focus:border-brand-400 focus:bg-white"
          >
            {columns.map((c) => (
              <option key={c} value={c}>{c}</option>
            ))}
          </select>
          <select
            value={f.operator}
            onChange={(e) => update(i, { operator: e.target.value })}
            className="h-9 rounded-lg border border-slate-200 bg-surface-subtle px-2.5 font-mono text-sm outline-none focus:border-brand-400 focus:bg-white"
          >
            {OPERATORS.map((o) => (
              <option key={o} value={o}>{o}</option>
            ))}
          </select>
          <input
            value={f.value}
            onChange={(e) => update(i, { value: e.target.value })}
            placeholder="value"
            className="h-9 flex-1 rounded-lg border border-slate-200 bg-surface-subtle px-3 text-sm outline-none focus:border-brand-400 focus:bg-white focus:ring-4 focus:ring-brand-400/10"
          />
          <button
            onClick={() => setDraft((d) => d.filter((_, idx) => idx !== i))}
            className="grid h-9 w-9 place-items-center rounded-lg text-ink-muted hover:bg-rose-50 hover:text-accent-rose"
          >
            <X className="h-4 w-4" />
          </button>
        </div>
      ))}
      <div className="flex items-center justify-between pt-1">
        <Button
          variant="ghost"
          size="sm"
          onClick={() => setDraft((d) => [...d, { column: columns[0] ?? "", operator: "=", value: "" }])}
        >
          <Plus className="h-3.5 w-3.5" />
          Add condition
        </Button>
        <div className="flex gap-2">
          <Button variant="secondary" size="sm" onClick={() => { setDraft([]); onApply([]); }}>
            Clear
          </Button>
          <Button size="sm" onClick={() => onApply(draft.filter((f) => f.column && f.value !== ""))}>
            Apply filters
          </Button>
        </div>
      </div>
    </Card>
  );
}

function CellValue({
  value,
  relation,
  onOpenRelation,
}: {
  value: unknown;
  relation?: { relatedRecords: Row[]; referencedTable: string };
  onOpenRelation?: (records: Row[], label: string) => void;
}) {
  if (value === null || value === undefined)
    return <span className="text-xs italic text-slate-400">null</span>;

  if (relation && relation.relatedRecords?.length && onOpenRelation) {
    return (
      <button
        onClick={() => onOpenRelation(relation.relatedRecords, `→ ${relation.referencedTable} (${String(value)})`)}
        className="inline-flex items-center gap-1 rounded-md bg-brand-50 px-1.5 py-0.5 font-mono text-xs text-brand-700 hover:bg-brand-100"
        title={`View related ${relation.referencedTable}`}
      >
        <Link2 className="h-3 w-3" />
        {truncate(String(value), 40)}
      </button>
    );
  }

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
