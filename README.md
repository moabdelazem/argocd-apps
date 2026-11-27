# ArgoCD Applications

This repository follows the **App of Apps** pattern: one root ArgoCD `Application` points at this repo, and ArgoCD deploys every other app defined here. Bootstrapping a new cluster means installing ArgoCD and applying the root app.

## Prerequisites

| Tool | Purpose | Install |
|------|---------|---------|
| [`kubectl`](https://kubernetes.io/docs/tasks/tools/) | Talk to the cluster | `curl -LO "https://dl.k8s.io/release/$(curl -Ls https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"` |
| [`helm`](https://helm.sh/docs/intro/install/) | Install ArgoCD and Helm-based apps | `curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 \| bash` |
| [`argocd`](https://argo-cd.readthedocs.io/en/stable/cli_installation/) | ArgoCD CLI (login, sync, inspect apps) | `curl -sSL -o argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64` |
| [`git`](https://git-scm.com/) | Clone and push changes to this repo | Package manager (`apt install git`) |

## Cluster: k8s vs k3s

The apps work on both, but the cluster setup differs.

| | Kubernetes (k8s) | k3s |
|---|---|---|
| What it is | Upstream, full Kubernetes distribution | Lightweight, CNCF-certified Kubernetes by Rancher/SUSE, single binary |
| Typical use | Production, multi-node, cloud (EKS/GKE/AKS) or `kubeadm` | Homelab, edge, IoT, dev, single-node or small clusters |
| Install | `kubeadm init` / managed cloud service | `curl -sfL https://get.k3s.io \| sh -` |
| Resources | Higher (control plane needs ~2 CPU / 2 GB+) | Low (runs on ~512 MB RAM) |
| Datastore | etcd | SQLite by default; embedded etcd or external DB for HA |
| Networking (CNI) | You choose and install one (Calico, Cilium, ...) | Flannel built in |
| Ingress | None by default, install one (e.g. ingress-nginx) | Traefik built in |
| Load balancer | Cloud LB or MetalLB on bare metal | ServiceLB (Klipper) built in |
| Storage | Cloud CSI driver or install one | `local-path` provisioner built in |
| Kubeconfig | `~/.kube/config` | `/etc/rancher/k3s/k3s.yaml` |

### k3s notes

- Copy the kubeconfig so `kubectl` works without sudo:
  ```bash
  mkdir -p ~/.kube
  sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
  sudo chown $(id -u):$(id -g) ~/.kube/config
  ```
- If you deploy your own ingress controller or load balancer from this repo (e.g. ingress-nginx, MetalLB), disable the built-in ones to avoid conflicts:
  ```bash
  curl -sfL https://get.k3s.io | sh -s - --disable traefik --disable servicelb
  ```

### k8s notes

- You must install a CNI before nodes become `Ready`.
- On bare metal, add a load balancer (e.g. MetalLB) and a storage provisioner; managed clouds provide these.

## Layout

Plain ArgoCD `Application` manifests that point at online Helm charts. Your config lives in a values file per app.

```
apps/root.yaml              # App of Apps: syncs everything in apps/
apps/<name>.yaml            # one Application per app: chart repo, chart, version
values/<name>.yaml          # your values for that chart
scripts/install-argocd.sh   # one-time bootstrap
```

**Add an app:** copy `apps/cert-manager.yaml` to `apps/<name>.yaml`, change the name, chart, version and namespace, and create `values/<name>.yaml`. Push, and ArgoCD deploys it.

**Change config or upgrade:** edit `values/<name>.yaml`, or `targetRevision` (the chart version) in `apps/<name>.yaml`, then push. This works for ArgoCD itself too.

## Bootstrap

```bash
scripts/install-argocd.sh
```

It Helm-installs ArgoCD with `values/argocd.yaml`, then applies `apps/root.yaml`. From there ArgoCD manages everything, itself included. Open http://argocd.devbox and log in as `admin` with the password the script prints.

## Branches

- `develop`: day-to-day work. Commit and test changes here.
- `main`: the release branch. Clusters sync from `main` (`targetRevision: main` in the `apps/` files), so a change reaches clusters only after it is merged from `develop` into `main`.
