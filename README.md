# Ares

A self-healing delivery platform that takes code from commit to production,
evaluates application and kernel-level signals, and automatically promotes or
rolls back a progressive deployment.

Ares combines Kubernetes-native deployment orchestration, Prometheus metrics,
an eBPF node agent, Terraform-managed infrastructure, and repeatable chaos
experiments. This repository currently contains the project scaffold only;
application behavior is intentionally not implemented yet.

See the [project specification](docs/SPECIFICATION.md) for the architecture,
component requirements, and suggested build order.

## Planned components

- `backend/` — Go operator, eBPF agent, CLI, API types, and decision engine
- `config/` — CRD, RBAC, manager, and sample Kubernetes manifests
- `deploy/kind/` — local Kubernetes cluster configuration
- `chaos/` — Chaos Mesh experiments and verification harness
- `database/migrations/` — PostgreSQL decision-audit migrations
- `observability/` — Prometheus and Grafana assets
- `infra/terraform/` — AKS, networking, and observability modules
- `web/` — optional React and TypeScript dashboard
- `docs/` — architecture and operating documentation

## Local prerequisites

- Go 1.23 or newer
- Docker
- `kubectl`
- `kind`
- `make`
- Node.js 20 or newer with npm (dashboard only)
- Terraform (cloud checkpoint only)

## Bootstrap

1. Copy `.env.example` to `.env` and adjust local values.
2. Run `make kind-up` to create the local Kubernetes cluster.
3. Run `docker compose up -d postgres` if local decision-history storage is
	needed.
4. Run `npm install` only when dashboard work begins.

The operator, agent, CRD schema, chaos tests, database schema, dashboards, and
Terraform resources are intentionally left for staged implementation.
