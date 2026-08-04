"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { cn } from "@/lib/utils";
import { navItems } from "./nav";
import { Hexagon } from "lucide-react";

export function Sidebar() {
  const pathname = usePathname();

  return (
    <aside className="hidden w-64 shrink-0 flex-col border-r border-slate-200/80 bg-white/70 px-4 py-5 backdrop-blur-xl lg:flex">
      <Link href="/dashboard" className="mb-8 flex items-center gap-2.5 px-2">
        <span className="grid h-9 w-9 place-items-center rounded-xl bg-gradient-to-br from-brand-500 to-accent-violet text-white shadow-glow">
          <Hexagon className="h-5 w-5" strokeWidth={2.4} />
        </span>
        <span className="text-base font-semibold tracking-tight text-ink">
          Post<span className="text-brand-600">Geek</span>
        </span>
      </Link>

      <nav className="flex flex-1 flex-col gap-1">
        {navItems.map((item) => {
          const active = pathname === item.href || pathname.startsWith(`${item.href}/`);
          const Icon = item.icon;
          return (
            <Link
              key={item.href}
              href={item.href}
              className={cn(
                "group relative flex items-center gap-3 rounded-xl px-3 py-2.5 text-sm font-medium transition-all",
                active
                  ? "bg-brand-50 text-brand-700"
                  : "text-ink-muted hover:bg-surface-sunken hover:text-ink",
              )}
            >
              {active ? (
                <span className="absolute left-0 top-1/2 h-5 w-1 -translate-y-1/2 rounded-r-full bg-brand-600" />
              ) : null}
              <Icon
                className={cn(
                  "h-4.5 w-4.5 shrink-0 transition-colors",
                  active ? "text-brand-600" : "text-slate-400 group-hover:text-ink",
                )}
                style={{ width: 18, height: 18 }}
              />
              <span>{item.label}</span>
            </Link>
          );
        })}
      </nav>

      <div className="mt-4 rounded-xl border border-slate-200/80 bg-gradient-to-br from-surface-subtle to-white p-3.5">
        <p className="text-xs font-medium text-ink">Tip</p>
        <p className="mt-1 text-[11px] leading-relaxed text-ink-muted">
          Enable <span className="font-mono text-brand-600">pg_stat_statements</span> for
          richer query insights.
        </p>
      </div>
    </aside>
  );
}
