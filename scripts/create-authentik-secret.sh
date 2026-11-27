#!/usr/bin/env bash
# Create authentik's secret key and Postgres password on the cluster (run once, before syncing authentik).
# Never recreates it: changing secret-key logs everyone out, and Postgres keeps the old password.
set -euo pipefail
NS=authentik
kubectl create namespace "$NS" --dry-run=client -o yaml | kubectl apply -f -
if kubectl -n "$NS" get secret authentik-secrets >/dev/null 2>&1; then
  echo "authentik-secrets already exists, leaving it alone"
  exit 0
fi
kubectl -n "$NS" create secret generic authentik-secrets \
  --from-literal=secret-key="$(openssl rand -base64 60 | tr -d '\n')" \
  --from-literal=postgres-password="$(openssl rand -base64 36 | tr -d '\n')"
echo "Created authentik-secrets in namespace $NS"
