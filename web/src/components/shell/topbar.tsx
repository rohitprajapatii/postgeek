"use client";

import { useRouter } from "next/navigation";
import { useConnection } from "@/lib/connection-context";
import { Button } from "@/components/ui/primitives";
import { LogOut, Server } from "lucide-react";
import { navItems } from "./nav";
import { usePathname } from "next/navigation";

export function Topbar() {
  const { connected, database, host, apiUrl, disconnect } = useConnection();
  const router = useRouter();
  const pathname = usePathname();

  const current = navItems.find(
    (item) => pathname === item.href || pathname.startsWith(`${item.href}/`),
  );

  const handleDisconnect = async () => {
    await disconnect();
    router.push("/");
  };

  return (
    <header className="sticky top-0 z-20 flex h-16 items-center justify-between gap-4 border-b border-slate-200/80 bg-surface-subtle/80 px-5 backdrop-blur-xl lg:px-8">
      <div>
        <h1 className="text-lg font-semibold tracking-tight text-ink">
          {current?.label ?? "PostGeek"}
        </h1>
        <p className="text-xs text-ink-muted">{current?.description}</p>
      </div>

      <div className="flex items-center gap-3">
        <div className="hidden items-center gap-2 rounded-xl border border-slate-200 bg-white px-3 py-1.5 sm:flex">
          <span className="relative flex h-2 w-2">
            <span
              className={
                connected
                  ? "absolute inline-flex h-full w-full animate-ping rounded-full bg-accent-teal opacity-60"
                  : "hidden"
              }
            />
            <span
              className={`relative inline-flex h-2 w-2 rounded-full ${
                connected ? "bg-accent-teal" : "bg-slate-300"
              }`}
            />
          </span>
          <Server className="h-3.5 w-3.5 text-ink-muted" />
          <span className="max-w-[220px] truncate text-xs font-medium text-ink">
            {connected ? database || host || apiUrl : "Not connected"}
          </span>
        </div>

        <Button variant="secondary" size="sm" onClick={handleDisconnect}>
          <LogOut className="h-3.5 w-3.5" />
          Disconnect
        </Button>
      </div>
    </header>
  );
}
