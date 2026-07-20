# Forge

Take a Git repository in and get a deployed, monitored, self-service-managed
service out.

Forge is a self-hosted internal developer platform built around a desired-state
reconciliation loop. This repository currently contains only the project
scaffold and local-development configuration; application features are not yet
implemented.

## Planned components

- `backend/` — Go API server and reconciler binaries
- `web/` — React and TypeScript dashboard
- `database/migrations/` — PostgreSQL schema migrations
- `observability/` — Prometheus and Grafana configuration
- `infra/terraform/` — hosting infrastructure
- `docs/` — architecture and operating documentation
- `scripts/` — development and automation scripts

## Local prerequisites

- Go 1.23 or newer
- Node.js 20 or newer with npm
- Docker with Docker Compose

## Bootstrap

1. Copy `.env.example` to `.env` and adjust local values.
2. Run `docker compose up -d` to start PostgreSQL and the local image registry.
3. Run `npm install` to install the dashboard toolchain when frontend work begins.

The API, reconciler, dashboard source, database schema, monitoring dashboards,
and Terraform resources are intentionally left for incremental implementation.
