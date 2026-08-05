"use client";

import { useState } from "react";
import type { Finding, Severity } from "@/lib/advisor";
import { cn } from "@/lib/utils";
import { AlertOctagon, AlertTriangle, Check, Copy, Info, Lightbulb } from "lucide-react";

const SEVERITY_STYLES: Record<
  Severity,
  { wrap: string; icon: typeof Info; iconColor: string; label: string }
> = {
  critical: {
    wrap: "border-rose-200 bg-rose-50/60",
    icon: AlertOctagon,
    iconColor: "text-rose-600",
    label: "Critical",
  },
  warning: {
    wrap: "border-amber-200 bg-amber-50/60",
    icon: AlertTriangle,
    iconColor: "text-amber-600",
    label: "Warning",
  },
  info: {
    wrap: "border-slate-200 bg-surface-subtle",
    icon: Info,
    iconColor: "text-slate-500",
    label: "Info",
  },
};

export function FindingCard({ finding }: { finding: Finding }) {
  const style = SEVERITY_STYLES[finding.severity];
  const Icon = style.icon;

  return (
    <div className={cn("rounded-xl border p-3.5", style.wrap)}>
      <div className="flex items-start gap-2.5">
        <Icon className={cn("mt-0.5 h-4 w-4 shrink-0", style.iconColor)} />
        <div className="min-w-0 flex-1">
          <p className="text-sm font-semibold text-ink">{finding.title}</p>
          <p className="mt-1 text-xs leading-relaxed text-ink-muted">{finding.detail}</p>
          <div className="mt-2 flex items-start gap-1.5">
            <Lightbulb className="mt-0.5 h-3.5 w-3.5 shrink-0 text-brand-500" />
            <p className="text-xs leading-relaxed text-ink">{finding.action}</p>
          </div>
          {finding.sql ? <CopyableSql sql={finding.sql} /> : null}
        </div>
      </div>
    </div>
  );
}

export function CopyableSql({ sql }: { sql: string }) {
  const [copied, setCopied] = useState(false);
  return (
    <div className="mt-2.5 flex items-center gap-2 rounded-lg bg-ink px-3 py-2">
      <code className="min-w-0 flex-1 overflow-x-auto font-mono text-[11px] leading-relaxed text-teal-100">
        {sql}
      </code>
      <button
        onClick={() => {
          navigator.clipboard?.writeText(sql);
          setCopied(true);
          setTimeout(() => setCopied(false), 1500);
        }}
        className="shrink-0 rounded-md p-1 text-slate-400 transition-colors hover:bg-white/10 hover:text-white"
        title="Copy"
      >
        {copied ? <Check className="h-3.5 w-3.5 text-teal-300" /> : <Copy className="h-3.5 w-3.5" />}
      </button>
    </div>
  );
}

export function FindingsList({
  findings,
  emptyLabel = "No issues detected.",
}: {
  findings: Finding[];
  emptyLabel?: string;
}) {
  if (!findings.length) {
    return <p className="px-1 py-2 text-xs text-ink-muted">{emptyLabel}</p>;
  }
  return (
    <div className="space-y-2">
      {findings.map((f) => (
        <FindingCard key={f.id} finding={f} />
      ))}
    </div>
  );
}

/** Compact severity dot summary, e.g. for a collapsed row. */
export function SeveritySummary({ findings }: { findings: Finding[] }) {
  const critical = findings.filter((f) => f.severity === "critical").length;
  const warning = findings.filter((f) => f.severity === "warning").length;

  if (!critical && !warning) return null;

  return (
    <span className="inline-flex items-center gap-1.5">
      {critical > 0 ? (
        <span className="inline-flex items-center gap-1 rounded-full bg-rose-50 px-2 py-0.5 text-[11px] font-medium text-rose-700 ring-1 ring-inset ring-rose-100">
          <AlertOctagon className="h-3 w-3" />
          {critical}
        </span>
      ) : null}
      {warning > 0 ? (
        <span className="inline-flex items-center gap-1 rounded-full bg-amber-50 px-2 py-0.5 text-[11px] font-medium text-amber-700 ring-1 ring-inset ring-amber-100">
          <AlertTriangle className="h-3 w-3" />
          {warning}
        </span>
      ) : null}
    </span>
  );
}
