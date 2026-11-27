#!/usr/bin/env bash
# Install ArgoCD on the current kubectl context, then hand everything to the root app.
# Usage: scripts/install-argocd.sh
set -euo pipefail
cd "$(dirname "$0")/.."

# same chart version ArgoCD will manage itself with (apps/argocd.yaml)
VERSION="$(awk '/targetRevision:/{print $2; exit}' apps/argocd.yaml)"
echo "Installing ArgoCD chart $VERSION on context: $(kubectl config current-context)"

helm upgrade --install argocd argo-cd --repo https://argoproj.github.io/argo-helm --version "$VERSION" \
  -n argocd --create-namespace -f values/argocd.yaml --wait

kubectl apply -f apps/root.yaml

echo "Password: $(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d)"
echo "UI: http://argocd.devbox (user: admin)"
