export function toNumber(value: unknown): number {
  if (value === null || value === undefined) return 0;
  const n = typeof value === "number" ? value : parseFloat(String(value));
  return Number.isFinite(n) ? n : 0;
}

export function formatNumber(value: unknown, maximumFractionDigits = 0): string {
  const n = toNumber(value);
  return n.toLocaleString("en-US", { maximumFractionDigits });
}

export function formatBytes(bytes: unknown): string {
  const n = toNumber(bytes);
  if (n === 0) return "0 B";
  const units = ["B", "KB", "MB", "GB", "TB", "PB"];
  const i = Math.floor(Math.log(n) / Math.log(1024));
  const value = n / Math.pow(1024, i);
  return `${value.toFixed(value >= 100 || i === 0 ? 0 : 1)} ${units[i]}`;
}

export function formatPercent(value: unknown, fractionDigits = 1): string {
  return `${toNumber(value).toFixed(fractionDigits)}%`;
}

export function formatDuration(seconds: unknown): string {
  const s = toNumber(seconds);
  if (s < 1) return `${Math.round(s * 1000)}ms`;
  if (s < 60) return `${s.toFixed(1)}s`;
  const m = Math.floor(s / 60);
  const rem = Math.round(s % 60);
  if (m < 60) return `${m}m ${rem}s`;
  const h = Math.floor(m / 60);
  return `${h}h ${m % 60}m`;
}

export function formatMs(ms: unknown): string {
  const n = toNumber(ms);
  if (n < 1) return `${n.toFixed(2)}ms`;
  if (n < 1000) return `${n.toFixed(1)}ms`;
  return `${(n / 1000).toFixed(2)}s`;
}

export function formatRelativeTime(value: unknown): string {
  if (!value) return "—";
  const date = new Date(String(value));
  if (Number.isNaN(date.getTime())) return "—";
  const diff = Date.now() - date.getTime();
  const sec = Math.round(diff / 1000);
  if (sec < 60) return `${sec}s ago`;
  const min = Math.round(sec / 60);
  if (min < 60) return `${min}m ago`;
  const hr = Math.round(min / 60);
  if (hr < 24) return `${hr}h ago`;
  const day = Math.round(hr / 24);
  return `${day}d ago`;
}

export function truncate(text: unknown, length = 80): string {
  const s = String(text ?? "");
  return s.length > length ? `${s.slice(0, length)}…` : s;
}

export function compactQuery(query: unknown): string {
  return String(query ?? "")
    .replace(/\s+/g, " ")
    .trim();
}
