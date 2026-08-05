import type { PlanNode, Row } from "./api";
import { toNumber } from "./format";

export type Severity = "critical" | "warning" | "info";

export interface Finding {
  id: string;
  severity: Severity;
  /** Short label — what is wrong. */
  title: string;
  /** Why it matters, with the numbers that triggered it. */
  detail: string;
  /** What to do about it. */
  action: string;
  /** Optional copy-pasteable remediation. */
  sql?: string;
}

const SEVERITY_RANK: Record<Severity, number> = {
  critical: 0,
  warning: 1,
  info: 2,
};

export function sortFindings(findings: Finding[]): Finding[] {
  return [...findings].sort(
    (a, b) => SEVERITY_RANK[a.severity] - SEVERITY_RANK[b.severity],
  );
}

function pct(n: number): string {
  return `${(n * 100).toFixed(1)}%`;
}

function ms(n: number): string {
  return n < 1000 ? `${n.toFixed(1)}ms` : `${(n / 1000).toFixed(2)}s`;
}

function num(n: number): string {
  return Math.round(n).toLocaleString("en-US");
}

/* ------------------------------------------------------------------ *
 * 1. Findings derived from pg_stat_statements counters                *
 * ------------------------------------------------------------------ */

export function analyzeQueryStats(
  row: Row,
  context: { totalExecTimeMs?: number } = {},
): Finding[] {
  const findings: Finding[] = [];

  const calls = toNumber(row.calls);
  const totalMs = toNumber(row.total_time_ms);
  const meanMs = toNumber(row.avg_time_ms);
  const maxMs = toNumber(row.max_time_ms);
  const stddev = toNumber(row.stddev_time_ms);
  const rows = toNumber(row.rows);
  const hit = toNumber(row.shared_blks_hit);
  const read = toNumber(row.shared_blks_read);
  const tempWritten = toNumber(row.temp_blks_written);
  const tempRead = toNumber(row.temp_blks_read);

  // Spilling to disk — almost always the single biggest win when present.
  if (tempWritten > 0 || tempRead > 0) {
    const blocks = Math.max(tempWritten, tempRead);
    const mb = (blocks * 8) / 1024;
    findings.push({
      id: "temp-spill",
      severity: mb > 32 ? "critical" : "warning",
      title: "Spilling to disk",
      detail: `Wrote ${num(blocks)} temp blocks (~${mb.toFixed(1)} MB) across ${num(calls)} call(s). Sorts, hashes or CTEs exceeded work_mem and fell back to disk.`,
      action:
        "Raise work_mem for this workload, or reduce the amount of data being sorted/hashed (filter earlier, add a supporting index so the planner can avoid the sort).",
      sql: "SET work_mem = '64MB';  -- session-level; tune in postgresql.conf for permanent effect",
    });
  }

  // Buffer cache effectiveness for this specific statement.
  const blocks = hit + read;
  if (blocks > 1000) {
    const hitRatio = hit / blocks;
    if (hitRatio < 0.9) {
      findings.push({
        id: "low-cache-hit",
        severity: hitRatio < 0.5 ? "critical" : "warning",
        title: "Low buffer cache hit ratio",
        detail: `Only ${pct(hitRatio)} of ${num(blocks)} block reads were served from cache (${num(read)} read from disk).`,
        action:
          "The query is touching more data than it needs, or the working set does not fit in shared_buffers. Add a selective index so fewer blocks are scanned, or increase shared_buffers.",
      });
    }
  }

  // Plan instability / parameter sensitivity.
  if (calls >= 10 && meanMs > 1 && stddev > meanMs) {
    findings.push({
      id: "unstable-timing",
      severity: "warning",
      title: "Highly variable execution time",
      detail: `Standard deviation (${ms(stddev)}) exceeds the mean (${ms(meanMs)}); slowest run was ${ms(maxMs)}.`,
      action:
        "Usually parameter-sensitive plans or lock contention. Compare EXPLAIN output for a fast vs slow parameter set, and check for blocking on the Activity page.",
    });
  }

  // Chatty query — the classic N+1 signature.
  if (calls >= 500 && meanMs < 5) {
    findings.push({
      id: "chatty",
      severity: totalMs > 1000 ? "warning" : "info",
      title: "Called very frequently",
      detail: `Executed ${num(calls)} times at ${ms(meanMs)} each, totalling ${ms(totalMs)}. Individually fast, but the call volume dominates.`,
      action:
        "Often an N+1 access pattern from the application. Batch these into a single query (IN / ANY / JOIN) or add a cache layer.",
    });
  }

  // Oversized result sets.
  if (calls > 0) {
    const rowsPerCall = rows / calls;
    if (rowsPerCall > 10_000) {
      findings.push({
        id: "large-result",
        severity: "warning",
        title: "Returns very large result sets",
        detail: `Averages ${num(rowsPerCall)} rows per call.`,
        action:
          "Add LIMIT/pagination, or aggregate in the database instead of shipping raw rows to the client.",
      });
    }
  }

  // Share of total database time.
  const totalDb = toNumber(context.totalExecTimeMs);
  if (totalDb > 0 && totalMs / totalDb > 0.25) {
    findings.push({
      id: "dominant-cost",
      severity: "warning",
      title: "Dominates total database time",
      detail: `Accounts for ${pct(totalMs / totalDb)} of all tracked execution time (${ms(totalMs)}).`,
      action:
        "Optimising this single statement will have the largest effect on overall database load.",
    });
  }

  // Plain slow.
  if (meanMs >= 100) {
    findings.push({
      id: "slow-mean",
      severity: meanMs >= 1000 ? "critical" : "warning",
      title: "Slow average execution",
      detail: `Mean execution time is ${ms(meanMs)} over ${num(calls)} call(s).`,
      action: "Run EXPLAIN ANALYZE to see which plan node is responsible.",
    });
  }

  if (!findings.length) {
    findings.push({
      id: "healthy",
      severity: "info",
      title: "No obvious problems",
      detail: `Mean ${ms(meanMs)} over ${num(calls)} call(s), cache hit ratio ${blocks ? pct(hit / blocks) : "n/a"}, no disk spills.`,
      action: "Nothing to act on from the collected counters.",
    });
  }

  return sortFindings(findings);
}

/* ------------------------------------------------------------------ *
 * 2. Findings derived from an EXPLAIN / EXPLAIN ANALYZE plan tree      *
 * ------------------------------------------------------------------ */

export interface PlanIssue extends Finding {
  /** Node the finding is attached to, for inline annotation. */
  nodePath: string;
}

function nodeLabel(node: PlanNode): string {
  const rel = node["Relation Name"];
  return rel ? `${node["Node Type"]} on ${rel}` : String(node["Node Type"]);
}

const SQL_NOISE_WORDS = new Set([
  "and", "or", "not", "null", "true", "false", "text", "integer", "numeric",
  "timestamp", "boolean", "bigint", "character", "varying", "date", "any",
]);

/**
 * Pull candidate column names out of a Filter / Index Cond expression,
 * ordered for B-tree index design: equality predicates first, then ranges,
 * then pattern matches. A composite index is only usable beyond its first
 * range column, so `(status, amount_cents)` beats `(amount_cents, status)`
 * for `status = 'x' AND amount_cents > n`.
 */
export function extractFilterColumns(expr: string | undefined): string[] {
  if (!expr) return [];

  // Capture the operator alongside the column so we can rank them.
  const re =
    /\(?\b(?:[a-zA-Z_][a-zA-Z0-9_]*\.)?([a-z_][a-z0-9_]*)\)?(?:::[a-zA-Z_ ]+)?\s*(=|>=|<=|>|<|<>|!=|~~\*?|IS\b|IN\b|ANY\b)/g;

  const rank = (op: string): number => {
    if (op === "=" || op.startsWith("IS") || op === "IN" || op === "ANY") return 0; // equality
    if (op === ">" || op === "<" || op === ">=" || op === "<=") return 1; // range
    return 2; // pattern / inequality
  };

  const best = new Map<string, number>();
  let m: RegExpExecArray | null;
  while ((m = re.exec(expr)) !== null) {
    const col = m[1];
    if (SQL_NOISE_WORDS.has(col)) continue;
    const r = rank(m[2].trim());
    const existing = best.get(col);
    if (existing === undefined || r < existing) best.set(col, r);
  }

  return Array.from(best.entries())
    .sort((a, b) => a[1] - b[1])
    .map(([col]) => col);
}

export function analyzePlan(
  root: PlanNode,
  opts: { analyzed: boolean; schema?: string } = { analyzed: false },
): PlanIssue[] {
  const issues: PlanIssue[] = [];

  const walk = (node: PlanNode, path: string) => {
    const type = String(node["Node Type"] ?? "");
    const planRows = toNumber(node["Plan Rows"]);
    const loops = Math.max(1, toNumber(node["Actual Loops"]) || 1);
    // EXPLAIN reports per-loop actual rows; total work is rows × loops.
    const actualRows = toNumber(node["Actual Rows"]) * loops;
    const removedByFilter = toNumber(node["Rows Removed by Filter"]) * loops;
    const relation = node["Relation Name"] as string | undefined;

    // --- Sequential scan that filters away most of what it reads ---
    if (type.includes("Seq Scan")) {
      const scanned = opts.analyzed ? actualRows + removedByFilter : planRows;
      const filterExpr = node["Filter"] as string | undefined;
      const big = scanned >= 5000;
      if (big && filterExpr) {
        const cols = extractFilterColumns(filterExpr);
        const suggestion =
          relation && cols.length
            ? `CREATE INDEX ON ${opts.schema ? `${opts.schema}.` : ""}${relation} (${cols.join(", ")});`
            : undefined;
        issues.push({
          nodePath: path,
          id: `seq-scan-${path}`,
          severity: scanned >= 100_000 ? "critical" : "warning",
          title: `Sequential scan on ${relation ?? "table"}`,
          detail: opts.analyzed
            ? `Read ${num(scanned)} rows and discarded ${num(removedByFilter)} of them (${scanned ? pct(removedByFilter / scanned) : "0%"}) via filter: ${filterExpr}`
            : `Planner expects to scan ${num(scanned)} rows with filter: ${filterExpr}`,
          action: cols.length
            ? `Add an index covering ${cols.map((c) => `"${c}"`).join(", ")} so the filter can be applied by an index scan instead of reading the whole table.`
            : "Add an index supporting this filter, or restructure the predicate so an existing index can be used.",
          sql: suggestion,
        });
      } else if (big && !filterExpr && scanned >= 100_000) {
        issues.push({
          nodePath: path,
          id: `seq-scan-full-${path}`,
          severity: "info",
          title: `Full scan of ${relation ?? "table"}`,
          detail: `Reads ${num(scanned)} rows with no filter.`,
          action:
            "Unavoidable if you genuinely need every row; otherwise add a WHERE clause or LIMIT.",
        });
      }
    }

    // --- Planner estimate badly wrong (only meaningful with ANALYZE) ---
    if (opts.analyzed && planRows > 0 && actualRows > 0) {
      const ratio =
        actualRows > planRows ? actualRows / planRows : planRows / actualRows;
      if (ratio >= 10 && Math.max(actualRows, planRows) > 100) {
        issues.push({
          nodePath: path,
          id: `estimate-${path}`,
          severity: ratio >= 100 ? "critical" : "warning",
          title: `Row estimate off by ${ratio.toFixed(0)}x`,
          detail: `${nodeLabel(node)} — planner expected ${num(planRows)} rows, actually got ${num(actualRows)}.`,
          action:
            "Bad estimates lead the planner to pick the wrong join and scan strategies. Refresh statistics, and consider extended statistics for correlated columns.",
          sql: relation
            ? `ANALYZE ${opts.schema ? `${opts.schema}.` : ""}${relation};`
            : "ANALYZE;",
        });
      }
    }

    // --- Sort or hash spilling to disk ---
    const sortSpaceType = node["Sort Space Type"] as string | undefined;
    if (sortSpaceType === "Disk") {
      const used = toNumber(node["Sort Space Used"]);
      issues.push({
        nodePath: path,
        id: `sort-disk-${path}`,
        severity: "critical",
        title: "Sort spilled to disk",
        detail: `${node["Sort Method"] ?? "Sort"} used ${num(used)} kB of disk instead of memory.`,
        action:
          "Increase work_mem so the sort fits in memory, or add an index that provides the required ordering and removes the sort entirely.",
        sql: "SET work_mem = '64MB';",
      });
    }
    if (toNumber(node["Peak Memory Usage"]) === 0 && toNumber(node["Hash Batches"]) > 1) {
      issues.push({
        nodePath: path,
        id: `hash-batches-${path}`,
        severity: "warning",
        title: "Hash join spilled to multiple batches",
        detail: `Hash used ${num(toNumber(node["Hash Batches"]))} batches, meaning the hash table did not fit in work_mem.`,
        action: "Increase work_mem, or reduce the size of the hashed relation.",
        sql: "SET work_mem = '64MB';",
      });
    }

    // --- Nested loop executing its inner side very many times ---
    if (type.includes("Nested Loop") && opts.analyzed) {
      const inner = (node.Plans ?? [])[1];
      const innerLoops = inner ? toNumber(inner["Actual Loops"]) : 0;
      if (innerLoops >= 10_000) {
        issues.push({
          nodePath: path,
          id: `nested-loop-${path}`,
          severity: "warning",
          title: "Nested loop with very many iterations",
          detail: `Inner side executed ${num(innerLoops)} times.`,
          action:
            "Usually caused by an underestimated outer row count. Fix the estimate (ANALYZE) or add an index so a hash/merge join becomes viable.",
        });
      }
    }

    (node.Plans ?? []).forEach((child, i) => walk(child, `${path}.${i}`));
  };

  walk(root, "0");
  return sortFindings(issues) as PlanIssue[];
}

/* ------------------------------------------------------------------ *
 * 3. Query shape helpers                                              *
 * ------------------------------------------------------------------ */

/** pg_stat_statements normalises literals to $1, $2 … */
export function isParameterized(query: string): boolean {
  return /\$\d+/.test(query);
}

/**
 * Whether we are willing to EXPLAIN this statement.
 *
 * Deliberately limited to read-only shapes: `EXPLAIN ANALYZE` *executes* the
 * statement, so offering it for INSERT/UPDATE/DELETE would silently mutate
 * data from a monitoring screen.
 */
export function isExplainable(query: string): boolean {
  const q = query.trim().toUpperCase();
  if (!q) return false;
  return /^(SELECT|WITH|VALUES|TABLE)\b/.test(q);
}

/**
 * Build the EXPLAIN statement for a query.
 *
 * pg_stat_statements normalises literals to `$1`, which a plain EXPLAIN
 * cannot plan. PostgreSQL 16+ handles this with GENERIC_PLAN — which cannot
 * be combined with ANALYZE, since there are no real values to execute with.
 */
export function buildExplainSql(
  query: string,
  opts: { analyze?: boolean } = {},
): { sql: string; analyzed: boolean; generic: boolean } {
  const trimmed = query.trim().replace(/;\s*$/, "");
  if (isParameterized(trimmed)) {
    return {
      sql: `EXPLAIN (GENERIC_PLAN, FORMAT JSON) ${trimmed}`,
      analyzed: false,
      generic: true,
    };
  }
  if (opts.analyze) {
    return {
      sql: `EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON) ${trimmed}`,
      analyzed: true,
      generic: false,
    };
  }
  return { sql: `EXPLAIN (FORMAT JSON) ${trimmed}`, analyzed: false, generic: false };
}
