"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { cn } from "@/lib/utils";
import { navItems } from "./nav";

export function MobileNav() {
  const pathname = usePathname();
  return (
    <nav className="sticky bottom-0 z-20 flex border-t border-slate-200/80 bg-white/90 backdrop-blur-xl lg:hidden">
      {navItems.map((item) => {
        const active = pathname === item.href || pathname.startsWith(`${item.href}/`);
        const Icon = item.icon;
        return (
          <Link
            key={item.href}
            href={item.href}
            className={cn(
              "flex flex-1 flex-col items-center gap-1 py-2.5 text-[10px] font-medium transition-colors",
              active ? "text-brand-600" : "text-ink-muted",
            )}
          >
            <Icon style={{ width: 18, height: 18 }} />
            {item.label}
          </Link>
        );
      })}
    </nav>
  );
}
