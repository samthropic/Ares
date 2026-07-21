# Terraform

Cloud infrastructure is separated into reusable modules and environment
composition:

- `modules/cluster/` — AKS cluster resources
- `modules/networking/` — ingress, DNS, and firewall resources
- `modules/observability/` — Prometheus and Grafana Helm releases
- `environments/azure/` — Azure environment composition

Local kind clusters are intentionally managed outside Terraform.
