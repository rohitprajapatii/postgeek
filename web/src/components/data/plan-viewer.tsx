"use client";

import { useState } from "react";
import type { PlanNode } from "@/lib/api";
import { analyzePlan, type PlanIssue } from "@/lib/advisor";
import { Badge } from "@/components/ui/primitives";
import { FindingsList, SeveritySummary } from "./findings";
import { CheckCircle2, ChevronDown, Lightbulb } from "lucide-react";
import { cn } from "@/lib/utils";
import { formatMs, formatNumber } from "@/lib/format";

export function PlanViewer({
  plan,
  analyzed,
  schema,
}: {
  plan: PlanNode;
  analyzed: boolean;
  schema?: string;
}) {
  // Determine the most expensive node (by total cost) to highlight hotspots.
  let maxCost = 0;
  const walk = (n: PlanNode) => {
    maxCost = Math.max(maxCost, n["Total Cost"] ?? 0);
    (n.Plans ?? []).forEach(walk);
  };
  walk(plan);

  const issues = analyzePlan(plan, { analyzed, schema });
  const byNode = new Map<string, PlanIssue[]>();
  for (const issue of issues) {
    const bucket = byNode.get(issue.nodePath);
    if (bucket) bucket.push(issue);
    else byNode.set(issue.nodePath, [issue]);
  }

  return (
    <div className="space-y-4">
      {issues.length ? (
        <div>
          <div className="mb-2 flex items-center gap-2">
            <Lightbulb className="h-4 w-4 text-brand-600" />
            <h4 className="text-sm font-semibold text-ink">
              {issues.length} optimization {issues.length === 1 ? "finding" : "findings"}
            </h4>
            <SeveritySummary findings={issues} />
          </div>
          <FindingsList findings={issues} />
        </div>
      ) : (
        <div className="flex items-center gap-2 rounded-xl border border-teal-200 bg-teal-50/60 px-3.5 py-2.5">
          <CheckCircle2 className="h-4 w-4 shrink-0 text-teal-600" />
          <p className="text-xs text-ink">
            No problems detected in this plan — no large sequential scans, disk spills or
            bad row estimates.
          </p>
        </div>
      )}

      <div>
        <h4 className="mb-2 text-sm font-semibold text-ink">Plan tree</h4>
        <div className="space-y-1.5">
          <PlanNodeRow
            node={plan}
            depth={0}
            path="0"
            maxCost={maxCost}
            analyzed={analyzed}
            issuesByNode={byNode}
          />
        </div>
      </div>
    </div>
  );
}

function PlanNodeRow({
  node,
  depth,
  path,
  maxCost,
  analyzed,
  issuesByNode,
}: {
  node: PlanNode;
  depth: number;
  path: string;
  maxCost: number;
  analyzed: boolean;
  issuesByNode: Map<string, PlanIssue[]>;
}) {
  const [open, setOpen] = useState(true);
  const children = node.Plans ?? [];
  const cost = node["Total Cost"] ?? 0;
  const costPct = maxCost ? (cost / maxCost) * 100 : 0;
  const hot = costPct >= 80;
  const nodeIssues = issuesByNode.get(path) ?? [];
  const worst = nodeIssues[0]?.severity;

  const target =
    node["Relation Name"] || node["Index Name"]
      ? `${node["Relation Name"] ?? ""}${node["Index Name"] ? ` · ${node["Index Name"]}` : ""}`
      : node["Join Type"]
        ? `${node["Join Type"]} join`
        : "";

  return (
    <div>
      <div
        className={cn(
          "rounded-xl border bg-white p-3 transition-colors",
          worst === "critical"
            ? "border-rose-300 bg-rose-50/50"
            : worst === "warning"
              ? "border-amber-300 bg-amber-50/40"
              : hot
                ? "border-rose-200 bg-rose-50/40"
                : "border-slate-200",
        )}
        style={{ marginLeft: depth * 18 }}
      >
        <div className="flex items-start justify-between gap-3">
          <div className="flex items-start gap-2">
            {children.length ? (
              <button onClick={() => setOpen((o) => !o)} className="mt-0.5 text-slate-400 hover:text-ink">
                <ChevronDown className={cn("h-4 w-4 transition-transform", !open && "-rotate-90")} />
              </button>
            ) : (
              <span className="mt-0.5 inline-block h-4 w-4" />
            )}
            <div>
              <div className="flex items-center gap-2">
                <span className="text-sm font-semibold text-ink">{node["Node Type"]}</span>
                {target ? <span className="font-mono text-xs text-brand-600">{target}</span> : null}
                {hot ? <Badge tone="rose">hotspot</Badge> : null}
                {nodeIssues.map((issue) => (
                  <Badge
                    key={issue.id}
                    tone={issue.severity === "critical" ? "rose" : "amber"}
                  >
                    {issue.title}
                  </Badge>
                ))}
              </div>
              <div className="mt-1 flex flex-wrap gap-x-4 gap-y-0.5 text-[11px] text-ink-muted">
                <span>cost {formatNumber(node["Startup Cost"])}…{formatNumber(node["Total Cost"])}</span>
                <span>rows {formatNumber(node["Plan Rows"])}</span>
                {analyzed ? (
                  <>
                    <span className="text-ink">actual {formatMs(node["Actual Total Time"])}</span>
                    <span>
                      rows {formatNumber(node["Actual Rows"])}
                      {node["Actual Loops"] && node["Actual Loops"]! > 1 ? ` ×${node["Actual Loops"]}` : ""}
                    </span>
                  </>
                ) : null}
              </div>
            </div>
          </div>
          <div className="w-20 shrink-0">
            <div className="h-1.5 w-full overflow-hidden rounded-full bg-slate-100">
              <div
                className={cn("h-full rounded-full", hot ? "bg-accent-rose" : "bg-brand-400")}
                style={{ width: `${Math.max(4, costPct)}%` }}
              />
            </div>
          </div>
        </div>
      </div>
      {open
        ? children.map((child, i) => (
            <div key={i} className="mt-1.5">
              <PlanNodeRow
                node={child}
                depth={depth + 1}
                path={`${path}.${i}`}
                maxCost={maxCost}
                analyzed={analyzed}
                issuesByNode={issuesByNode}
              />
            </div>
          ))
        : null}
    </div>
  );
}
