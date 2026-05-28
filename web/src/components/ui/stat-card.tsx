"use client";

import { cn } from "@/lib/utils";
import type { LucideIcon } from "lucide-react";
import type { ReactNode } from "react";

type Tone = "brand" | "teal" | "amber" | "rose" | "violet" | "neutral";

const toneStyles: Record<Tone, { bg: string; text: string }> = {
  brand: { bg: "bg-brand-50", text: "text-brand-600" },
  teal: { bg: "bg-teal-50", text: "text-teal-600" },
  amber: { bg: "bg-amber-50", text: "text-amber-600" },
  rose: { bg: "bg-rose-50", text: "text-rose-600" },
  violet: { bg: "bg-violet-50", text: "text-violet-600" },
  neutral: { bg: "bg-slate-100", text: "text-slate-600" },
};

export function StatCard({
  label,
  value,
  hint,
  icon: Icon,
  tone = "brand",
  footer,
}: {
  label: string;
  value: ReactNode;
  hint?: ReactNode;
  icon: LucideIcon;
  tone?: Tone;
  footer?: ReactNode;
}) {
  const styles = toneStyles[tone];
  return (
    <div className="card card-pad transition-transform duration-200 hover:-translate-y-0.5 hover:shadow-card">
      <div className="flex items-center justify-between">
        <span className="text-xs font-medium uppercase tracking-wide text-ink-muted">
          {label}
        </span>
        <span className={cn("grid h-8 w-8 place-items-center rounded-xl", styles.bg, styles.text)}>
          <Icon className="h-4 w-4" />
        </span>
      </div>
      <div className="mt-3 text-2xl font-semibold tracking-tight text-ink">{value}</div>
      {hint ? <p className="mt-1 text-xs text-ink-muted">{hint}</p> : null}
      {footer ? <div className="mt-3">{footer}</div> : null}
    </div>
  );
}
