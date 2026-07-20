# Backend

This Go module will contain two binaries:

- `cmd/api` for the stateless REST API server
- `cmd/reconciler` for the desired-state control loop

Shared packages should live under `internal/`. No backend behavior is
implemented in the initial scaffold.