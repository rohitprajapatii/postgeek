<div align="center">

<img src="https://img.shields.io/badge/NestJS-Backend-e0234e?style=for-the-badge&logo=nestjs&logoColor=white" alt="NestJS" />
<img src="https://img.shields.io/badge/Flutter-Web-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter" />
<img src="https://img.shields.io/badge/PostgreSQL-DB-4169E1?style=for-the-badge&logo=postgresql&logoColor=white" alt="PostgreSQL" />
<img src="https://img.shields.io/badge/Docker-Compose-2496ED?style=for-the-badge&logo=docker&logoColor=white" alt="Docker" />

<h1>PostGeek</h1>
<p><i>A PostgreSQL monitoring and data studio</i></p>

<p>
  <a href="#quick-start">Quick Start</a> •
  <a href="#screenshots">Screenshots</a> •
  <a href="#features">Features</a> •
  <a href="#project-structure">Project Structure</a> •
  <a href="#configuration">Configuration</a> •
  <a href="#local-development">Local Development</a> •
  <a href="#troubleshooting">Troubleshooting</a>
 </p>

</div>

---

### About

PostGeek is a self-hosted PostgreSQL dashboard that helps you connect to any Postgres instance and visualize essential health, activity, queries, and manage your data—all from a sleek Web Interface

---

### Quick Start

Prerequisites:

- Docker and Docker Compose installed

Run:

```bash
docker compose up -d --build
```

Then open:

- Frontend (NGINX): http://localhost:8081
- Backend API (NestJS): http://localhost:3000/api/health

Notes:

- First build will download Flutter/Dart toolchains and may take a few minutes.

---

### Screenshots

Place the following images under `docs/screenshots/` to render inline.

<div align="center">

<img src="docs/screenshots/dashboard.png" alt="Dashboard" width="900" />
<br/><sub>Dashboard</sub>
<br/><br/>

<img src="docs/screenshots/connection.png" alt="Connection Screen" width="520" />
<br/><sub>Connect to any PostgreSQL instance</sub>
<br/><br/>

<img src="docs/screenshots/loading.png" alt="Loading" width="520" />
<br/><sub>Initialization state</sub>
<br/><br/>

<img src="docs/screenshots/activity-locks.png" alt="Activity - Locks" width="900" />
<br/><sub>Database Activity: Granted Locks</sub>
<br/><br/>

<img src="docs/screenshots/activity-idle.png" alt="Activity - Idle Sessions" width="900" />
<br/><sub>Database Activity: Idle Sessions</sub>
<br/><br/>

<img src="docs/screenshots/data-studio-feedback.png" alt="Data Studio - Feedback table" width="900" />
<br/><sub>Data Studio: Explore and filter tables</sub>

</div>

---

### Features

- **Universal connection**: Connect via connection string or fields; smart strategies for Docker/local/external DBs
- **Health insights**: Missing/unused indexes, table bloat, and key status endpoints
- **Activity views**: Active sessions, idle sessions, locks, blocked queries
- **Query explorer**: Run and inspect SQL with helpful metrics
- **Data Studio**: Browse schemas, search tables, preview rows
- **Production ready builds**: Multi-stage Docker (NestJS + Flutter Web on NGINX)

---

### Project Structure

```text
postgeek/
  backend/           # NestJS API (port 3000, path prefix /api)
  frontend/          # Flutter Web app
  docker/            # NGINX config and helpers
  Dockerfile         # Multi-stage build (backend + Flutter web + nginx)
  docker-compose.yml # Run backend + frontend together
```

---

### Configuration

Out of the box, no environment variables are strictly required. You provide DB credentials from the UI. The backend has enhanced environment detection for Docker vs local.

- Backend server: listens on port `3000` with prefix `/api`
- Frontend server: served by NGINX on port `80` in-container → mapped to `8081` on host (see `docker-compose.yml`)

If you need to run the backend against protected/external databases, ensure your DB allows inbound connections and SSL as required. The backend may attempt connection variants like `host.docker.internal` or common Docker gateway IPs for convenience.

API highlights:

- `GET /api/health` – service health and DB checks
- `POST /api/database/connect` – connect using a connection string or host/port/db/user/pass
- `DELETE /api/database/disconnect` – close connection
- `GET /api/database/status` – see whether you’re connected

---

### Local Development

Option A — Docker (recommended):

```bash
docker compose up -d --build
```

Option B — Run services locally:

1. Backend (Node 18+)

```bash
cd backend
npm install
npm run start:dev
```

2. Frontend (Flutter 3.22+ recommended)

```bash
cd frontend
flutter pub get
flutter run -d chrome
```

Convenience from monorepo root:

```bash
npm run start:dev
```

---

### Troubleshooting

- Flutter in Docker fails downloading Dart SDK or complains about running as root

  - This project clones Flutter’s stable branch and runs Flutter commands as a non-root user in the build stage.
  - If you previously cached layers, rebuild clean: `docker compose build --no-cache frontend`.

- Cannot connect to a DB from Docker
  - Try `host.docker.internal` as host, or expose/forward your DB port properly.
  - Ensure the DB accepts connections from your network (pg_hba.conf, listen_addresses).

---

### License

Copyright © 2025. All rights reserved.
