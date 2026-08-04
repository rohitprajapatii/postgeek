"use client";

import { cn } from "@/lib/utils";
import type { ReactNode } from "react";

export interface Column<T> {
  key: string;
  header: ReactNode;
  render?: (row: T) => ReactNode;
  align?: "left" | "right" | "center";
  className?: string;
}

export function DataTable<T extends Record<string, unknown>>({
  columns,
  rows,
  rowKey,
  dense,
  emptyLabel = "No rows to display.",
}: {
  columns: Column<T>[];
  rows: T[];
  rowKey: (row: T, index: number) => string | number;
  dense?: boolean;
  emptyLabel?: string;
}) {
  if (!rows.length) {
    return (
      <div className="px-5 py-10 text-center text-sm text-ink-muted">{emptyLabel}</div>
    );
  }

  const align = {
    left: "text-left",
    right: "text-right",
    center: "text-center",
  };

  return (
    <div className="scrollbar-thin overflow-x-auto">
      <table className="w-full border-collapse text-sm">
        <thead>
          <tr className="border-b border-slate-200">
            {columns.map((col) => (
              <th
                key={col.key}
                className={cn(
                  "whitespace-nowrap px-4 py-2.5 text-xs font-semibold uppercase tracking-wide text-ink-muted",
                  align[col.align ?? "left"],
                )}
              >
                {col.header}
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          {rows.map((row, i) => (
            <tr
              key={rowKey(row, i)}
              className="border-b border-slate-100 transition-colors last:border-0 hover:bg-surface-subtle"
            >
              {columns.map((col) => (
                <td
                  key={col.key}
                  className={cn(
                    "px-4 align-middle text-ink",
                    dense ? "py-2" : "py-3",
                    align[col.align ?? "left"],
                    col.className,
                  )}
                >
                  {col.render ? col.render(row) : String(row[col.key] ?? "—")}
                </td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
