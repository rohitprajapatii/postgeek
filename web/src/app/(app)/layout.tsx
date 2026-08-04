"use client";

import { useEffect } from "react";
import { useRouter } from "next/navigation";
import { useConnection } from "@/lib/connection-context";
import { Sidebar } from "@/components/shell/sidebar";
import { Topbar } from "@/components/shell/topbar";
import { Spinner } from "@/components/ui/primitives";
import { MobileNav } from "@/components/shell/mobile-nav";

export default function AppLayout({ children }: { children: React.ReactNode }) {
  const { connected, checking } = useConnection();
  const router = useRouter();

  useEffect(() => {
    if (!checking && !connected) {
      router.replace("/");
    }
  }, [checking, connected, router]);

  if (checking) {
    return (
      <div className="flex min-h-screen items-center justify-center">
        <div className="flex flex-col items-center gap-3">
          <Spinner className="h-6 w-6" />
          <p className="text-sm text-ink-muted">Checking connection…</p>
        </div>
      </div>
    );
  }

  if (!connected) {
    return (
      <div className="flex min-h-screen items-center justify-center">
        <Spinner className="h-6 w-6" />
      </div>
    );
  }

  return (
    <div className="flex min-h-screen">
      <Sidebar />
      <div className="flex min-w-0 flex-1 flex-col">
        <Topbar />
        <main className="flex-1 px-5 py-6 lg:px-8 lg:py-8">
          <div className="mx-auto w-full max-w-7xl animate-fade-in">{children}</div>
        </main>
        <MobileNav />
      </div>
    </div>
  );
}
