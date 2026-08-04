"use client";

import { useMemo, useState } from "react";
import { useMutation } from "@tanstack/react-query";
import { api, ApiError, type ColumnInfo, type Row, type TableInfo } from "@/lib/api";
import { Drawer } from "@/components/ui/modal";
import { Button, Badge } from "@/components/ui/primitives";
import { AlertTriangle, KeyRound, Link2 } from "lucide-react";
import { cn } from "@/lib/utils";

type Mode = "create" | "edit";

const NUMERIC = ["integer", "bigint", "smallint", "numeric", "decimal", "real", "double precision"];

function inputTypeFor(dataType: string): "number" | "checkbox" | "datetime-local" | "text" {
  if (NUMERIC.includes(dataType)) return "number";
  if (dataType === "boolean") return "checkbox";
  if (dataType.startsWith("timestamp")) return "datetime-local";
  return "text";
}

export function RecordForm({
  schema,
  table,
  info,
  mode,
  initial,
  onClose,
  onSaved,
}: {
  schema: string;
  table: string;
  info: TableInfo;
  mode: Mode;
  initial?: Row;
  onClose: () => void;
  onSaved: () => void;
}) {
  const editableColumns = useMemo(
    () =>
      info.columns.filter((c) => {
        // On create, hide identity/serial columns that the DB fills in.
        if (mode === "create" && (c.isIdentity || /nextval\(/.test(c.defaultValue ?? ""))) {
          return false;
        }
        return true;
      }),
    [info.columns, mode],
  );

  const [form, setForm] = useState<Record<string, string>>(() => {
    const init: Record<string, string> = {};
    editableColumns.forEach((c) => {
      const v = initial?.[c.columnName];
      init[c.columnName] = v === null || v === undefined ? "" : String(v);
    });
    return init;
  });
  const [touched, setTouched] = useState<Set<string>>(new Set());

  const buildPayload = (): Row => {
    const data: Row = {};
    for (const col of editableColumns) {
      const raw = form[col.columnName];
      // On edit only send changed fields; on create send non-empty.
      if (mode === "edit" && !touched.has(col.columnName)) continue;
      if (raw === "" ) {
        if (col.isNullable) data[col.columnName] = null;
        continue;
      }
      if (col.dataType === "boolean") data[col.columnName] = raw === "true";
      else if (NUMERIC.includes(col.dataType)) data[col.columnName] = Number(raw);
      else data[col.columnName] = raw;
    }
    return data;
  };

  const save = useMutation({
    mutationFn: async () => {
      const data = buildPayload();
      if (mode === "create") return api.createRecord(schema, table, data);
      const where: Row = {};
      const keys = info.primaryKeys.length ? info.primaryKeys : Object.keys(initial ?? {});
      for (const k of keys) {
        if (k.startsWith("_")) continue;
        where[k] = initial?.[k] ?? null;
      }
      return api.updateRecord(schema, table, data, where);
    },
    onSuccess: () => onSaved(),
  });

  const errorMessage =
    save.error instanceof ApiError || save.error instanceof Error ? save.error.message : null;

  const setField = (name: string, value: string) => {
    setForm((f) => ({ ...f, [name]: value }));
    setTouched((t) => new Set(t).add(name));
  };

  return (
    <Drawer
      open
      onClose={onClose}
      title={mode === "create" ? "Add record" : "Edit record"}
      subtitle={`${schema}.${table}`}
      footer={
        <div className="flex items-center justify-end gap-2">
          <Button variant="secondary" size="sm" onClick={onClose}>
            Cancel
          </Button>
          <Button size="sm" loading={save.isPending} onClick={() => save.mutate()}>
            {mode === "create" ? "Create" : "Save changes"}
          </Button>
        </div>
      }
    >
      {errorMessage ? (
        <div className="mb-4 flex items-start gap-2 rounded-xl border border-rose-200 bg-rose-50 px-3 py-2 text-xs text-rose-700">
          <AlertTriangle className="mt-0.5 h-3.5 w-3.5 shrink-0" />
          <span className="font-mono">{errorMessage}</span>
        </div>
      ) : null}

      <div className="space-y-3.5">
        {editableColumns.map((col) => (
          <Field key={col.columnName} col={col} value={form[col.columnName] ?? ""} onChange={(v) => setField(col.columnName, v)} />
        ))}
      </div>
    </Drawer>
  );
}

function Field({
  col,
  value,
  onChange,
}: {
  col: ColumnInfo;
  value: string;
  onChange: (v: string) => void;
}) {
  const type = inputTypeFor(col.dataType);
  return (
    <label className="block">
      <span className="mb-1 flex items-center gap-1.5 text-xs font-medium text-ink">
        {col.columnName}
        {col.isPrimaryKey ? <Badge tone="amber"><KeyRound className="h-2.5 w-2.5" />PK</Badge> : null}
        {col.isForeignKey ? <Badge tone="brand"><Link2 className="h-2.5 w-2.5" />FK</Badge> : null}
        <span className="font-mono font-normal text-slate-400">{col.dataType}</span>
        {!col.isNullable ? <span className="text-accent-rose">*</span> : null}
      </span>
      {type === "checkbox" ? (
        <select
          value={value}
          onChange={(e) => onChange(e.target.value)}
          className="h-10 w-full rounded-xl border border-slate-200 bg-surface-subtle px-3 text-sm outline-none focus:border-brand-400 focus:bg-white focus:ring-4 focus:ring-brand-400/10"
        >
          <option value="">—</option>
          <option value="true">true</option>
          <option value="false">false</option>
        </select>
      ) : (
        <input
          type={type}
          value={value}
          onChange={(e) => onChange(e.target.value)}
          placeholder={col.isNullable ? "null" : ""}
          className={cn(
            "h-10 w-full rounded-xl border border-slate-200 bg-surface-subtle px-3 text-sm outline-none transition-all placeholder:text-slate-400 focus:border-brand-400 focus:bg-white focus:ring-4 focus:ring-brand-400/10",
            type === "number" && "font-mono",
          )}
        />
      )}
    </label>
  );
}
