# Kubernetes configuration

This directory is reserved for Kubebuilder-generated and hand-authored
Kubernetes manifests:

- `crd/bases/` — `ProgressiveRollout` CRD definitions
- `manager/` — operator manager deployment
- `rbac/` — service accounts, roles, and bindings
- `samples/` — example rollout resources

The manifests will be introduced with Checkpoint A. No CRD or controller is
implemented in the initial scaffold.
