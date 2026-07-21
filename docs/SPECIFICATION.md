# Ares — A Self-Healing Delivery Platform

## One-line pitch

A platform that takes code from commit to production, automatically detects
when something is wrong using real system-level signals—not just application
metrics—and heals or rolls back without a human. It spans deployment
orchestration, deep observability, infrastructure automation, and verified
resilience.

## Why this project

Most portfolio infrastructure projects pick one layer—a deployment tool, a
monitoring dashboard, or a Terraform module—and stop. Ares deliberately
integrates four layers that together mirror what a senior platform engineer
actually owns: provisioning, deployment, deep signal, and verification. The
individual pieces are legitimate projects on their own; the larger story is
that they compose into one coherent system.

---

## Architecture overview

```text
 ┌────────────────────────────────────────────────────────────────┐
 │                         Terraform (IaC)                        │
 │   Provisions: K8s cluster, ingress, Prometheus/Grafana, DB     │
 └───────────────────────────┬────────────────────────────────────┘
                             │
                   ┌─────────▼─────────┐
                   │    Kubernetes     │
                   │      Cluster      │
                   └─────────┬─────────┘
                             │
       ┌─────────────────────┼─────────────────────┐
       │                     │                     │
┌──────▼──────────┐  ┌───────▼─────────┐  ┌────────▼────────┐
│ Ares Operator   │  │ eBPF Agent      │  │ App Workloads   │
│ (Go, CRD +      │  │ (DaemonSet,     │  │ (test services) │
│ controller-     │  │ cilium/ebpf)    │  │                 │
│ runtime)        │  │                 │  │                 │
└──────┬──────────┘  └───────┬─────────┘  └─────────────────┘
       │                     │
       │             ┌───────▼────────┐
       │             │  Prometheus    │
       │             │ (app + kernel  │
       │             │    metrics)    │
       │             └───────┬────────┘
       │                     │
       └──────────┬──────────┘
                  │
          ┌───────▼──────────┐
          │ Decision Engine  │
          │ (operator        │
          │ reconciliation)  │
          └───────┬──────────┘
                  │
       ┌──────────┴───────────┐
       │                      │
┌──────▼──────┐       ┌───────▼───────┐
│ Promote to  │       │ Auto-rollback │
│ 100% traffic│       │ + alert       │
└─────────────┘       └───────────────┘

          ┌──────────────────────────┐
          │ Chaos Suite (offline)    │
          │ Validates rollback       │
          │ against pod kills,       │
          │ latency, and packet loss │
          └──────────────────────────┘
```

---

## Recommended tech stack

| Layer | Technology | Why |
| --- | --- | --- |
| Operator/controller | **Go + controller-runtime (Kubebuilder)** | The standard production-grade way to build Kubernetes operators. |
| Custom resources | **Kubernetes CRDs** | A native extension point; `kubectl get progressiverollout` works normally. |
| Traffic splitting | **NGINX Ingress canary annotations** initially; **Linkerd** as a stretch goal | NGINX weighted routing is quick to establish. Linkerd adds mTLS and finer traffic control without Istio's weight. |
| Application metrics | **Prometheus + Grafana** | Industry-standard metrics collection, querying, and visualization. |
| Kernel-level signals | **eBPF via `cilium/ebpf`** | Traces TCP and syscall behavior without custom kernel modules. |
| Decision audit store | **PostgreSQL** | Stores rollout decisions and history; live desired state remains in Kubernetes objects. |
| Infrastructure | **Terraform**, with **AKS** for Azure or **kind/k3d** locally | Demonstrates IaC while keeping local iteration fast and inexpensive. |
| Chaos injection | **Chaos Mesh**, or a small custom Go tool | Kubernetes-native pod, latency, and packet-loss experiments expressed as CRDs. |
| CLI/dashboard | **Go CLI with Cobra** initially; **React + TypeScript** as a stretch goal | A CLI is sufficient for early demos; the dashboard adds later polish. |
| Project CI | **GitHub Actions** | Builds, tests, and lints the operator on every change. |

### Local development environment

Build and iterate against **kind** (Kubernetes-in-Docker) to avoid cloud costs.
Only create the Terraform-managed cloud cluster—preferably AKS for
Azure-focused roles—for final integration testing and demonstrations.

---

## Component specifications

### 1. Custom resource: `ProgressiveRollout`

```yaml
apiVersion: rollout.ares.dev/v1
kind: ProgressiveRollout
metadata:
  name: my-app-rollout
spec:
  targetDeployment: my-app
  steps:
    - setWeight: 10
      pause: 5m
    - setWeight: 50
      pause: 5m
    - setWeight: 100
  metrics:
    - name: error-rate
      source: prometheus
      query: 'sum(rate(http_requests_total{status=~"5.."}[1m]))'
      threshold: 0.02
    - name: tcp-retransmits
      source: ebpf
      threshold: 50 # retransmits/sec, exported by the eBPF agent
status:
  phase: Progressing # Progressing | Promoting | RollingBack | Healthy | Failed
  currentWeight: 10
  lastEvaluatedAt: "..."
```

Including an `ebpf` metric source alongside `prometheus` in the same schema is
the detail that distinguishes deep observability from simply watching HTTP
status codes.

### 2. Operator and decision engine (Go)

- Use a standard controller-runtime reconciliation loop. Watch
  `ProgressiveRollout` objects, compare the desired step and weight with the
  observed cluster state, and act on mismatches.
- At the end of each `pause` window, query Prometheus for both application and
  eBPF-agent metrics before advancing to the next step.
- If either source breaches its threshold, trigger a rollback: scale the new
  ReplicaSet to zero, restore the old traffic weight to 100%, set
  `.status.phase` to `RollingBack`, and emit a Kubernetes Event visible through
  `kubectl describe`.
- Preserve idempotency and crash recovery. If the operator restarts during a
  rollout, it resumes from Kubernetes state and `.status` rather than starting
  the rollout again.

### 3. eBPF agent (DaemonSet)

- Run an agent on every node and attach eBPF programs that trace:
  - TCP retransmits and connection resets scoped to pods in the active rollout.
  - Syscall latency, such as slow `read` and `write` calls indicating I/O
    contention.
- Expose kernel signals through a Prometheus `/metrics` endpoint. The operator
  queries Prometheus rather than communicating directly with eBPF programs,
  keeping responsibilities separated.
- Start with TCP retransmits only. Add connection resets and syscall latency
  after the first signal is reliable and demonstrable.

### 4. Terraform modules

- `modules/cluster` provisions the Kubernetes cluster, using AKS for the
  Azure-targeted environment.
- `modules/observability` installs Prometheus and Grafana with the Helm
  provider.
- `modules/networking` installs the ingress controller and configures required
  DNS and firewall resources.
- Keep kind-based local development separate from Terraform-managed cloud
  environments. Terraform should not manage the local development loop.

### 5. Chaos suite

- Define Chaos Mesh `PodChaos` experiments that terminate a pod during a
  rollout.
- Define `NetworkChaos` experiments that inject latency or packet loss into the
  new ReplicaSet specifically.
- Provide a small test harness that starts a rollout, triggers an experiment at
  a known rollout phase, and asserts that the operator rolls back within a
  bounded time.
- Record rollback time so the self-healing claim is measurable and repeatable.

---

## Build order

Each checkpoint must remain a complete, independently demoable project.

1. **Checkpoint A — Operator only.** Build the CRD and controller-runtime
   reconciler, weighted traffic shifting through NGINX Ingress annotations,
   and Prometheus-based rollback decisions on a kind cluster. This is a strong
   standalone project if development stops here.
2. **Checkpoint B — Add the eBPF agent.** Begin with TCP retransmits and wire
   the exported metric into the operator as a second threshold source.
3. **Checkpoint C — Add Terraform.** Provision the cloud cluster and
   observability stack through IaC, then move the demo environment from kind to
   the Terraform-managed cluster.
4. **Checkpoint D — Add the chaos suite.** Automate pod-kill and network-delay
   experiments against a live rollout and capture rollback-time measurements.
5. **Stretch — Dashboard.** Add a React and TypeScript view of rollout status,
   live metrics, and the traffic-weight curve.

---

## Honest scope

This is a multi-week project when implemented properly: approximately four to
eight weeks of focused evening or weekend work across all four checkpoints.
Checkpoint A alone is achievable in a focused week for someone familiar with
Go and Kubernetes. Each checkpoint is a real stopping point so the repository
always contains something complete and demoable rather than a partially built
system.

## Interview talking points

- Why rollback decisions based only on HTTP metrics can miss failures such as
  connection-pool exhaustion and retry storms, and how eBPF signals close that
  gap.
- How the operator survives its own crash during a rollout by reconciling from
  Kubernetes state and `.status` instead of relying on in-memory state.
- Why chaos experiments validate the self-healing claim more credibly than
  asserting that rollback logic works.
- The tradeoff in observation windows and threshold tuning: windows that are
  too short or thresholds too loose miss regressions, while conservative
  settings slow every deployment.
