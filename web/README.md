# PostGeek Web (Next.js)

A lightweight, modern web frontend for PostGeek — a fresh alternative to the
Flutter Web client in `../frontend`. Built with **Next.js 14 (App Router)**,
**TypeScript**, **Tailwind CSS**, **TanStack Query** and **Recharts**.

It talks to the same NestJS backend (`../backend`) and ships a much smaller
payload than the Flutter build (~90 kB shared JS vs. several MB of Flutter
runtime + canvas).

## Features

- **Connection** – connect via individual credentials or a connection string,
  with a configurable backend API URL.
- **Overview** – database size, cache hit ratio, connections, transactions,
  live activity counts, buffer-cache and write-workload charts, heaviest queries.
- **Activity** – active/idle sessions, locks and blocked queries, with the
  ability to terminate a backend PID. Active sessions auto-refresh.
- **Queries** – workload stats, time-by-query-type chart and an expandable
  slow-query list (with a `pg_stat_statements` reset action).
- **Health** – cache ratio, dead tuples & vacuum status, possibly-missing and
  unused indexes, and table bloat.
- **Data Studio** – searchable schema/table browser, paginated data viewer,
  table structure inspector, and a SQL console with a read-only safety toggle.

## Getting started

```bash
cd web
npm install
npm run dev      # http://localhost:3001
```

Make sure the backend is running (default `http://localhost:3000`):

```bash
cd ../backend
npm install
npm run start:dev
```

On the connection screen, set the **Backend API URL** if your backend is not on
`http://localhost:3000`, then connect to any PostgreSQL instance.

## Configuration

| Variable                     | Default                  | Description                          |
| ---------------------------- | ------------------------ | ------------------------------------ |
| `NEXT_PUBLIC_DEFAULT_API_URL`| `http://localhost:3000`  | Pre-filled backend URL on the form.  |

The chosen API URL is persisted in `localStorage`; credentials are sent only to
the backend and never stored in the browser.

## Build

```bash
npm run build && npm run start   # serves on :3001
```

The app is configured with `output: "standalone"` for easy containerization.

## Docker

A `web` service is wired into the repo's `docker-compose.yml` (port `3001`),
alongside the existing Flutter client (`8081`) and backend (`3000`):

```bash
docker compose up -d --build web backend
# Next.js web → http://localhost:3001
# Backend API → http://localhost:3000/api
```

To build the image directly (from the repo root):

```bash
docker build -f web/Dockerfile -t postgeek-web \
  --build-arg NEXT_PUBLIC_DEFAULT_API_URL=http://localhost:3000 .
docker run -p 3001:3001 postgeek-web
```

`NEXT_PUBLIC_DEFAULT_API_URL` only sets the *default* value on the form; the
URL the browser actually calls is whatever you enter on the connection screen,
so it must be reachable from your browser (e.g. the host-mapped backend port).
