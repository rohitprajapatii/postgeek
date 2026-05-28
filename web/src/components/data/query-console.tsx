"use client";

import { useState } from "react";
import { useMutation } from "@tanstack/react-query";
import { api, ApiError, type PlanNode, type QueryResult } from "@/lib/api";
import { Card, Badge, Button } from "@/components/ui/primitives";
import { PlanViewer } from "./plan-viewer";
import { AlertTriangle, GitBranch, Play, ShieldAlert, ShieldCheck } from "lucide-react";
import { cn } from "@/lib/utils";
import { formatNumber, truncate } from "@/lib/format";

type Output = { kind: "rows"; result: QueryResult; message: string } | { kind: "plan"; plan: PlanNode; analyzed: boolean };

export function QueryConsole({ schema, table }: { schema: string; table: string }) {
  const [sql, setSql] = useState(`SELECT * FROM ${schema}.${table} LIMIT 100;`);
  const [readonly, setReadonly] = useState(true);
  const [output, setOutput] = useState<Output | null>(null);
  const [error, setError] = useState<string | null>(null);

  const run = useMutation({
    mutationFn: () => api.executeQuery(sql, readonly),
    onSuccess: (res) => {
      setError(null);
      setOutput({ kind: "rows", result: res.data, message: res.message });
    },
    onError: (e) => setError(e instanceof Error ? e.message : "Query failed"),
  });

  const explain = useMutation({
    mutationFn: async (analyze: boolean) => {
      const opts = analyze ? "ANALYZE, BUFFERS, FORMAT JSON" : "FORMAT JSON";
      const res = await api.executeQuery(`EXPLAIN (${opts}) ${sql}`, true);
      const raw = res.data.rows[0]?.["QUERY PLAN"] as Array<{ Plan: PlanNode }> | undefined;
      if (!raw || !raw[0]?.Plan) throw new ApiError("Could not parse query plan", 500);
      return { plan: raw[0].Plan, analyzed: analyze };
    },
    onSuccess: ({ plan, analyzed }) => {
      setError(null);
      setOutput({ kind: "plan", plan, analyzed });
    },
    onError: (e) => setError(e instanceof Error ? e.message : "Explain failed"),
  });

  const busy = run.isPending || explain.isPending;
  const handleRun = () => sql.trim() && run.mutate();

  return (
    <div className="space-y-4">
      <Card className="overflow-hidden">
        <div className="flex flex-wrap items-center justify-between gap-2 border-b border-slate-100 px-4 py-2.5">
          <div className="flex items-center gap-2 text-sm font-medium text-ink-muted">
            <Play className="h-4 w-4 text-brand-600" />
            SQL Console
          </div>
          <div className="flex flex-wrap items-center gap-2">
            <button
              type="button"
              onClick={() => setReadonly((r) => !r)}
              className={cn(
                "inline-flex items-center gap-1.5 rounded-lg px-2.5 py-1.5 text-xs font-medium transition-colors",
                readonly ? "bg-teal-50 text-teal-700" : "bg-rose-50 text-rose-700",
              )}
              title="Toggle read-only safety"
            >
              {readonly ? <ShieldCheck className="h-3.5 w-3.5" /> : <ShieldAlert className="h-3.5 w-3.5" />}
              {readonly ? "Read-only" : "Write enabled"}
            </button>
            <Button variant="secondary" size="sm" onClick={() => sql.trim() && explain.mutate(false)} loading={explain.isPending && !explain.variables}>
              <GitBranch className="h-3.5 w-3.5" />
              Explain
            </Button>
            <Button variant="secondary" size="sm" onClick={() => sql.trim() && explain.mutate(true)} loading={explain.isPending && explain.variables === true}>
              Analyze
            </Button>
            <Button size="sm" onClick={handleRun} loading={run.isPending}>
              <Play className="h-3.5 w-3.5" />
              Run
            </Button>
          </div>
        </div>
        <textarea
          value={sql}
          onChange={(e) => setSql(e.target.value)}
          spellCheck={false}
          onKeyDown={(e) => {
            if ((e.metaKey || e.ctrlKey) && e.key === "Enter") handleRun();
          }}
          disabled={busy}
          className="h-44 w-full resize-none bg-ink p-4 font-mono text-sm text-teal-100 outline-none placeholder:text-slate-500"
          placeholder="Write SQL here… (⌘/Ctrl + Enter to run)"
        />
        {!readonly ? (
          <div className="flex items-center gap-2 bg-rose-50 px-4 py-2 text-xs text-rose-700">
            <AlertTriangle className="h-3.5 w-3.5" />
            Write mode is on — INSERT, UPDATE and DELETE will modify your data.
          </div>
        ) : null}
      </Card>

      {error ? (
        <Card className="card-pad border-rose-200 bg-rose-50">
          <div className="flex items-start gap-2 text-sm text-rose-700">
            <AlertTriangle className="mt-0.5 h-4 w-4 shrink-0" />
            <span className="font-mono text-xs">{error}</span>
          </div>
        </Card>
      ) : null}

      {output?.kind === "plan" ? (
        <Card className="card-pad">
          <div className="mb-3 flex items-center gap-2">
            <GitBranch className="h-4 w-4 text-brand-600" />
            <h3 className="text-sm font-semibold text-ink">Query plan</h3>
            <Badge tone={output.analyzed ? "teal" : "neutral"}>
              {output.analyzed ? "EXPLAIN ANALYZE" : "EXPLAIN"}
            </Badge>
          </div>
          <PlanViewer plan={output.plan} analyzed={output.analyzed} />
        </Card>
      ) : null}

      {output?.kind === "rows" ? (
        <Card>
          <div className="flex flex-wrap items-center gap-2 border-b border-slate-100 px-4 py-2.5 text-xs">
            <Badge tone="teal">{output.message}</Badge>
            <span className="text-ink-muted">{formatNumber(output.result.rowCount)} rows</span>
          </div>
          <div className="scrollbar-thin max-h-[50vh] overflow-auto">
            {output.result.rows.length ? (
              <table className="w-full border-collapse text-sm">
                <thead className="sticky top-0 bg-white">
                  <tr className="border-b border-slate-200">
                    {output.result.fields.map((f) => (
                      <th key={f.name} className="whitespace-nowrap px-4 py-2.5 text-left text-xs font-semibold uppercase tracking-wide text-ink-muted">
                        {f.name}
                        <span className="ml-1 font-normal lowercase text-slate-400">{f.dataType}</span>
                      </th>
                    ))}
                  </tr>
                </thead>
                <tbody>
                  {output.result.rows.map((row, i) => (
                    <tr key={i} className="border-b border-slate-100 last:border-0 hover:bg-surface-subtle">
                      {output.result.fields.map((f) => {
                        const v = row[f.name];
                        return (
                          <td key={f.name} className="max-w-xs truncate px-4 py-2.5">
                            {v === null || v === undefined ? (
                              <span className="text-xs italic text-slate-400">null</span>
                            ) : typeof v === "object" ? (
                              <code className="font-mono text-xs text-violet-600">{truncate(JSON.stringify(v), 60)}</code>
                            ) : (
                              <span title={String(v)}>{truncate(String(v), 80)}</span>
                            )}
                          </td>
                        );
                      })}
                    </tr>
                  ))}
                </tbody>
              </table>
            ) : (
              <div className="px-4 py-8 text-center text-sm text-ink-muted">
                Query executed successfully — no rows returned.
              </div>
            )}
          </div>
        </Card>
      ) : null}
    </div>
  );
}
