# Ares Go components

This module will contain three binaries:

- `cmd/operator` — the Kubernetes controller and rollout decision engine
- `cmd/agent` — the eBPF node agent and Prometheus metrics endpoint
- `cmd/aresctl` — the operator-facing CLI

Versioned `ProgressiveRollout` API types belong under `api/`. Controller,
decision, metrics, and eBPF implementation packages belong under `internal/`.
No runtime behavior is implemented in the initial scaffold.