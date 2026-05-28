"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { api, ApiError, DEFAULT_API_URL } from "@/lib/api";
import { useConnection } from "@/lib/connection-context";
import { Button } from "@/components/ui/primitives";
import {
  ArrowRight,
  Database,
  Hexagon,
  KeyRound,
  Link2,
  Lock,
  Server,
  ShieldCheck,
  Sparkles,
  Activity,
  Gauge,
} from "lucide-react";
import { cn } from "@/lib/utils";

type Mode = "string" | "fields";

export default function ConnectionPage() {
  const router = useRouter();
  const { connected, checking, markConnected, updateApiUrl } = useConnection();

  const [mode, setMode] = useState<Mode>("fields");
  const [apiUrl, setLocalApiUrl] = useState(DEFAULT_API_URL);
  const [connectionString, setConnectionString] = useState("");
  const [host, setHost] = useState("localhost");
  const [port, setPort] = useState("5432");
  const [database, setDatabase] = useState("");
  const [username, setUsername] = useState("");
  const [password, setPassword] = useState("");
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!checking && connected) router.replace("/dashboard");
  }, [checking, connected, router]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    setSubmitting(true);
    updateApiUrl(apiUrl);

    try {
      if (mode === "string") {
        if (!connectionString.trim()) throw new ApiError("Enter a connection string.", 400);
        await api.connect({ connectionString: connectionString.trim() });
      } else {
        if (!host || !database || !username)
          throw new ApiError("Host, database and username are required.", 400);
        await api.connect({
          host,
          port: Number(port) || 5432,
          database,
          username,
          password,
        });
      }
      markConnected({ database: database || undefined, host: host || undefined });
      router.push("/dashboard");
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to connect.");
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div className="relative min-h-screen overflow-hidden bg-ink text-white">
      {/* Aurora background */}
      <div className="pointer-events-none absolute inset-0">
        <div className="absolute -left-40 -top-40 h-[36rem] w-[36rem] rounded-full bg-brand-500/30 blur-[120px]" />
        <div className="absolute -right-32 top-20 h-[30rem] w-[30rem] rounded-full bg-accent-violet/30 blur-[120px]" />
        <div className="absolute bottom-0 left-1/3 h-[28rem] w-[28rem] rounded-full bg-accent-teal/20 blur-[120px]" />
      </div>
      <div className="grain pointer-events-none absolute inset-0 opacity-40" />

      <div className="relative mx-auto grid min-h-screen max-w-6xl grid-cols-1 items-center gap-10 px-6 py-12 lg:grid-cols-2 lg:gap-16">
        {/* Hero */}
        <div className="animate-fade-in">
          <div className="mb-6 inline-flex items-center gap-2.5">
            <span className="grid h-11 w-11 place-items-center rounded-2xl bg-white/10 text-white ring-1 ring-white/20 backdrop-blur">
              <Hexagon className="h-6 w-6" strokeWidth={2.2} />
            </span>
            <span className="text-2xl font-semibold tracking-tight">
              Post<span className="text-brand-300">Geek</span>
            </span>
          </div>

          <h1 className="text-4xl font-semibold leading-tight tracking-tight sm:text-5xl">
            A calmer way to watch your{" "}
            <span className="bg-gradient-to-r from-brand-300 via-violet-300 to-teal-300 bg-clip-text text-transparent">
              PostgreSQL
            </span>
          </h1>
          <p className="mt-4 max-w-md text-base leading-relaxed text-white/70">
            Connect to any Postgres instance and explore health, live activity, query
            workload and your data — in a fast, lightweight studio.
          </p>

          <div className="mt-9 grid max-w-md grid-cols-2 gap-3 sm:grid-cols-2">
            {[
              { icon: Gauge, label: "Live vitals", note: "Cache, size & connections" },
              { icon: Activity, label: "Activity", note: "Sessions, locks, blocks" },
              { icon: Database, label: "Query insight", note: "Slow & heavy workloads" },
              { icon: ShieldCheck, label: "Health checks", note: "Indexes & bloat" },
            ].map((f) => (
              <div
                key={f.label}
                className="rounded-2xl border border-white/10 bg-white/5 p-4 backdrop-blur transition-colors hover:bg-white/10"
              >
                <f.icon className="h-5 w-5 text-brand-300" />
                <p className="mt-2.5 text-sm font-medium">{f.label}</p>
                <p className="text-xs text-white/50">{f.note}</p>
              </div>
            ))}
          </div>
        </div>

        {/* Form card */}
        <div className="animate-fade-in">
          <form
            onSubmit={handleSubmit}
            className="rounded-3xl border border-white/10 bg-white/95 p-6 text-ink shadow-2xl backdrop-blur-xl sm:p-7"
          >
            <div className="mb-5 flex items-center gap-2">
              <Sparkles className="h-4 w-4 text-brand-500" />
              <h2 className="text-base font-semibold">Connect to a database</h2>
            </div>

            <Field
              icon={<Link2 className="h-4 w-4" />}
              label="Backend API URL"
              value={apiUrl}
              onChange={setLocalApiUrl}
              placeholder="http://localhost:3000"
            />

            <div className="my-4 flex rounded-xl bg-surface-sunken p-1">
              <TabButton active={mode === "fields"} onClick={() => setMode("fields")}>
                Credentials
              </TabButton>
              <TabButton active={mode === "string"} onClick={() => setMode("string")}>
                Connection string
              </TabButton>
            </div>

            {mode === "string" ? (
              <Field
                icon={<Database className="h-4 w-4" />}
                label="Connection string"
                value={connectionString}
                onChange={setConnectionString}
                placeholder="postgresql://user:pass@host:5432/db"
                mono
              />
            ) : (
              <div className="space-y-3">
                <div className="grid grid-cols-3 gap-3">
                  <div className="col-span-2">
                    <Field
                      icon={<Server className="h-4 w-4" />}
                      label="Host"
                      value={host}
                      onChange={setHost}
                      placeholder="localhost"
                    />
                  </div>
                  <Field label="Port" value={port} onChange={setPort} placeholder="5432" />
                </div>
                <Field
                  icon={<Database className="h-4 w-4" />}
                  label="Database"
                  value={database}
                  onChange={setDatabase}
                  placeholder="postgres"
                />
                <div className="grid grid-cols-2 gap-3">
                  <Field
                    icon={<KeyRound className="h-4 w-4" />}
                    label="Username"
                    value={username}
                    onChange={setUsername}
                    placeholder="postgres"
                  />
                  <Field
                    icon={<Lock className="h-4 w-4" />}
                    label="Password"
                    value={password}
                    onChange={setPassword}
                    placeholder="••••••••"
                    type="password"
                  />
                </div>
              </div>
            )}

            {error ? (
              <div className="mt-4 rounded-xl border border-rose-200 bg-rose-50 px-3.5 py-2.5 text-xs text-rose-700">
                {error}
              </div>
            ) : null}

            <Button type="submit" loading={submitting} className="mt-5 w-full">
              {submitting ? "Connecting…" : "Connect"}
              {!submitting ? <ArrowRight className="h-4 w-4" /> : null}
            </Button>

            <p className="mt-3 text-center text-[11px] text-ink-muted">
              Credentials are sent only to your backend — never stored in the browser.
            </p>
          </form>
        </div>
      </div>
    </div>
  );
}

function TabButton({
  active,
  onClick,
  children,
}: {
  active: boolean;
  onClick: () => void;
  children: React.ReactNode;
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      className={cn(
        "flex-1 rounded-lg px-3 py-1.5 text-xs font-medium transition-all",
        active ? "bg-white text-ink shadow-soft" : "text-ink-muted hover:text-ink",
      )}
    >
      {children}
    </button>
  );
}

function Field({
  label,
  value,
  onChange,
  placeholder,
  icon,
  type = "text",
  mono,
}: {
  label: string;
  value: string;
  onChange: (v: string) => void;
  placeholder?: string;
  icon?: React.ReactNode;
  type?: string;
  mono?: boolean;
}) {
  return (
    <label className="block">
      <span className="mb-1.5 block text-xs font-medium text-ink-muted">{label}</span>
      <div className="relative">
        {icon ? (
          <span className="pointer-events-none absolute left-3 top-1/2 -translate-y-1/2 text-slate-400">
            {icon}
          </span>
        ) : null}
        <input
          type={type}
          value={value}
          onChange={(e) => onChange(e.target.value)}
          placeholder={placeholder}
          className={cn(
            "h-11 w-full rounded-xl border border-slate-200 bg-surface-subtle px-3.5 text-sm text-ink outline-none transition-all placeholder:text-slate-400 focus:border-brand-400 focus:bg-white focus:ring-4 focus:ring-brand-400/10",
            icon ? "pl-9" : "",
            mono ? "font-mono text-xs" : "",
          )}
        />
      </div>
    </label>
  );
}
