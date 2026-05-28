"use client";

import { AlertTriangle, RefreshCw } from "lucide-react";
import { Button, Skeleton } from "./primitives";
import { ApiError } from "@/lib/api";

export function QueryError({
  error,
  onRetry,
}: {
  error: unknown;
  onRetry?: () => void;
}) {
  const message =
    error instanceof ApiError || error instanceof Error
      ? error.message
      : "Something went wrong while loading this data.";
  return (
    <div className="flex flex-col items-center gap-3 px-6 py-10 text-center">
      <div className="grid h-11 w-11 place-items-center rounded-2xl bg-amber-50 text-amber-600">
        <AlertTriangle className="h-5 w-5" />
      </div>
      <p className="max-w-md text-sm text-ink">{message}</p>
      {onRetry ? (
        <Button variant="secondary" size="sm" onClick={onRetry}>
          <RefreshCw className="h-3.5 w-3.5" />
          Retry
        </Button>
      ) : null}
    </div>
  );
}

export function TableSkeleton({ rows = 6 }: { rows?: number }) {
  return (
    <div className="space-y-2 p-5">
      {Array.from({ length: rows }).map((_, i) => (
        <Skeleton key={i} className="h-9 w-full" />
      ))}
    </div>
  );
}

export function CardSkeleton() {
  return (
    <div className="card card-pad space-y-3">
      <Skeleton className="h-4 w-24" />
      <Skeleton className="h-8 w-32" />
      <Skeleton className="h-3 w-full" />
    </div>
  );
}
