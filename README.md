# Homelab Kubernetes Cluster — Complete Infrastructure as Code

A **Git-first, DevOps-ready** home lab built on:
- **3× HP EliteDesk 800 G2 Mini** (i5-6500T, 26GB RAM, 1-2TB NVMe)
- **Ubuntu 24.04 LTS** with automated autoinstall
- **Tailscale** for secure mesh networking with SSH support
- **Kubernetes 1.30** (kubeadm) with Flannel CNI
- **Longhorn** for replicated storage
- **Six self-hosted services** (Pi-hole, Vaultwarden, Gitea, Nextcloud, Immich, Audiobookshelf)
- **Fully version-controlled in Git** (GitHub staging → Gitea production)

---

## Quick Start (TL;DR)

```bash
# 1. Fork/clone this repo to GitHub (private)
git clone https://github.com/yourname/homelab-infra.git
cd homelab-infra

# 2. Customize with your IPs, passwords, SSH keys
cp ansible/inventory/hosts.yml.example ansible/inventory/hosts.yml
nano ansible/inventory/hosts.yml

cp autoinstall/cp-01/user-data.example autoinstall/cp-01/user-data
nano autoinstall/cp-01/user-data
# ... repeat for worker-01, worker-02

# 3. Flash USB sticks, boot nodes (autoinstall is hands-off)
# (See AUTOINSTALL.md)

# 4. Deploy everything
TS_AUTHKEY=tskey-auth-xxx ./deploy.sh all

# 5. Once Gitea is running, migrate from GitHub to Gitea
git remote add gitea https://gitea.yourdomain.ts.net/homelab/homelab-infra.git
git push gitea main
git remote remove origin
```

Done. Your infrastructure is now in Git on your tailnet.

---

## Prerequisites

**Hardware:**
- 3× HP EliteDesk 800 G2 Mini (or compatible)
- 10-way PDU (for power)
- 2× 1TB+ M.2 2242 SATA drives (or 2280 NVMe if it fits)
- Backup storage for your data (NAS, external drive, cloud)

**Tools:**
- Linux machine with Ansible, kubectl, Helm
- SSH key pair (`ssh-keygen -t ed25519`)
- Tailscale account (free: https://tailscale.com)
- Private GitHub account (temporary bootstrap)

**Data:**
- Backups of: Nextcloud, Gitea (2-3GB), Immich (40GB), Vaultwarden
- Cronjob verification for Nextcloud backup to NAS

---

## Architecture

```
┌─────────────────────── Tailscale Mesh (100.x.x.x) ──────────────────────┐
│                                                                             │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐                │
│  │  cp-01       │    │  worker-01   │    │  worker-02   │                │
│  │ 192.168.1.10 │    │ 192.168.1.11 │    │ 192.168.1.12 │                │
│  │              │    │              │    │              │                │
│  │ • Pi-hole    │    │ • Vaultwarden│    │ • Immich     │                │
│  │ • etcd       │    │ • Gitea      │    │ • Audiobooksh│                │
│  │ • kube-apisvr│    │ • Nextcloud  │    │              │                │
│  │ • Postgres   │    │ • Redis      │    │ ← 1TB NVMe   │                │
│  │              │    │ ← 1TB NVMe   │    │              │                │
│  └──────────────┘    └──────────────┘    └──────────────┘                │
│         ↓                    ↓                    ↓                        │
│   Longhorn + local-path storage on each node    │        │
│         ↓                    ↓                    ↓        │
│   All services accessible via ingress-nginx + TLS   │
│         ↓                    ↓                    ↓        │
│   Pi-hole DNS on MetalLB IP (10.0.0.1)              │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## File Structure

```
homelab-infra/
├── .gitignore                 # Protect sensitive config
├── README.md                  # This file
├── GIT-FIRST-WORKFLOW.md      # How to use GitHub → Gitea
├── deploy.sh                  # Master orchestration script
│
├── autoinstall/               # Ubuntu 24.04 autoinstall configs
│   ├── cp-01/
│   │   ├── user-data.example  # Template (GitHub safe)
│   │   ├── user-data          # Your config (gitignored)
│   │   └── meta-data
│   ├── worker-01/
│   └── worker-02/
│
├── ansible/                   # Infrastructure automation
│   ├── site.yml               # Phase 1: OS setup
│   ├── k8s-bootstrap.yml      # Phase 2: Kubernetes
│   ├── k8s-install-addons.yml # Phase 2b: Add-ons
│   ├── inventory/
│   │   └── hosts.yml.example  # Template
│   │   └── hosts.yml          # Your IPs (gitignored)
│   ├── group_vars/
│   │   └── all.yml            # Tailscale, sysctl, etc.
│   └── roles/
│       ├── base/              # OS hardening + Tailscale
│       ├── containerd/        # Container runtime
│       ├── kubernetes-common/  # k8s packages
│       └── kubeadm/           # Control plane init
│
├── k8s/                       # Kubernetes manifests
│   ├── base/
│   │   ├── namespaces.yaml
│   │   ├── storage-classes.yaml
│   │   └── ingress.yaml       # TLS with cert-manager
│   └── services/
│       └── README.md          # See original package for full manifests
│
└── scripts/
    ├── restore-nextcloud.sh
    ├── restore-gitea.sh
    └── setup-immich-library.sh
```

---

## Deployment Phases

### Phase 1: OS Setup
- **What:** Install Ubuntu 24.04 on all nodes
- **How:** Autoinstall (fully automated via cloud-init)
- **Tools:** Ansible (base role)
- **Duration:** ~10 mins per node
- **Command:** `TS_AUTHKEY=xxx ./deploy.sh os`

### Phase 2: Kubernetes Bootstrap
- **What:** kubeadm init, join workers, install Flannel CNI
- **How:** Automated Ansible playbooks
- **Duration:** ~5 mins
- **Command:** `./deploy.sh bootstrap`

### Phase 2b: Install Cluster Add-ons
- **What:** Longhorn, local-path, MetalLB, ingress, cert-manager
- **How:** Helm charts via Ansible
- **Duration:** ~5 mins
- **Command:** `./deploy.sh addons`

### Phase 3: Deploy Services
- **What:** All six services (Gitea, Nextcloud, Immich, etc.)
- **How:** kubectl apply manifests
- **Duration:** ~2 mins (deployment takes ~30 seconds per pod)
- **Command:** `./deploy.sh services`

### Phase 4: Data Restoration
- **What:** Restore your backups into services
- **How:** Helper scripts
- **Duration:** Varies (40GB Immich ~ 1 hour via rsync)
- **Command:** `./scripts/restore-*.sh /path/to/backup`

---

## Getting Started

### Step 1: Prepare Configuration

```bash
# Copy example files
cp ansible/inventory/hosts.yml.example ansible/inventory/hosts.yml
cp autoinstall/cp-01/user-data.example autoinstall/cp-01/user-data
cp autoinstall/worker-01/user-data.example autoinstall/worker-01/user-data
cp autoinstall/worker-02/user-data.example autoinstall/worker-02/user-data

# Edit with YOUR values
nano ansible/inventory/hosts.yml
nano autoinstall/cp-01/user-data
nano autoinstall/worker-01/user-data
nano autoinstall/worker-02/user-data
```

**What to change:**
- IPs (192.168.1.10, 11, 12)
- SSH bootstrap key (cat ~/.ssh/id_ed25519.pub)
- Hashed password (echo "pass" | mkpasswd --method=SHA-512 --stdin)
- NIC name (check with `ip link` on live boot)

### Step 2: Commit to GitHub

```bash
git add ansible/ autoinstall/
git commit -m "Configure for my home lab"
git push origin main
```

### Step 3: Flash USB Sticks

Use Ventoy or Balena Etcher with Ubuntu 24.04 ISO + autoinstall configs.

### Step 4: Deploy

```bash
# Get Tailscale auth key
# https://login.tailscale.com/admin/settings/keys

# Run deployment
TS_AUTHKEY=tskey-auth-xxx ./deploy.sh all

# Or phase by phase
./deploy.sh os
./deploy.sh bootstrap
./deploy.sh addons
./deploy.sh services
```

### Step 5: Migrate to Gitea

Once Gitea is running:

```bash
git remote add gitea https://gitea.yourdomain.ts.net/homelab/homelab-infra.git
git push gitea main
git remote remove origin

# Now Gitea is your single source of truth
```

---

## Verification

```bash
# Cluster status
kubectl get nodes          # All 3 should be Ready
kubectl get pods -A        # All services Running

# Ingress & TLS
kubectl get ingress -A
kubectl get certificate -A  # All should be True

# Storage
kubectl get sc             # longhorn-replicated, local-path
kubectl get pvc -A         # All should be Bound

# Services
kubectl get svc -A         # Pi-hole should have MetalLB IP
```

---

## Data Restoration

### Nextcloud

```bash
./scripts/restore-nextcloud.sh /path/to/nextcloud-backup
```

### Gitea

```bash
./scripts/restore-gitea.sh /path/to/gitea-backup.tar
```

### Immich

```bash
./scripts/setup-immich-library.sh /path/to/immich-library  # ~40GB
```

### Vaultwarden

Vaultwarden has built-in export/import. See service docs.

---

## Accessing Services

All services accessible over Tailscale (no port forwarding needed):

```
https://vaultwarden.yourdomain.ts.net
https://gitea.yourdomain.ts.net
https://nextcloud.yourdomain.ts.net
https://immich.yourdomain.ts.net
https://audiobookshelf.yourdomain.ts.net
https://pihole.yourdomain.ts.net/admin
```

Configure Tailscale DNS to use Pi-hole:
1. Tailscale admin console → DNS → Global nameservers
2. Add Pi-hole MetalLB IP (e.g., 10.0.0.1)
3. Enable "Override local DNS"
4. All devices on tailnet now use Pi-hole automatically

---

## Maintenance

### Backup Strategy

- **Longhorn PVCs:** Built-in snapshots (dashboard)
- **local-path PVCs:** Daily rsync to NAS/backup drive
- **Databases:** CronJobs for automated dumps

### Upgrades

- **Kubernetes:** `kubeadm upgrade` (plan for maintenance window)
- **Services:** Update image tags in manifests, re-apply
- **OS:** Automatic security patches via `unattended-upgrades`

### Monitoring (Optional, Future)

Add Prometheus + Grafana via Helm for visibility:
```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install prometheus prometheus-community/kube-prometheus-stack -n monitoring --create-namespace
```

---

## Troubleshooting

### Nodes not joining
```bash
# Check kubeadm logs
sudo journalctl -xe | grep kubeadm

# Reset (destructive)
sudo kubeadm reset
```

### PVC stuck in Pending
```bash
kubectl describe pvc <pvc> -n <namespace>
kubectl logs -n longhorn-system -l app=longhorn-manager | tail -50
```

### Tailscale SSH not working
```bash
# Check SSH is enabled
tailscale status

# Re-enable
sudo tailscale up --ssh
```

---

## Philosophy

This is a **DevOps-first home lab** designed around these principles:

1. **Infrastructure as Code** — Everything in Git, nothing manual
2. **Reproducible** — Destroy and rebuild in <30 minutes
3. **Auditable** — Every change is a Git commit
4. **Self-Hosted** — Your code lives on your hardware, not external services
5. **Tailscale-First** — No port forwarding, no dynamic DNS complexity
6. **Offline-Capable** — Rebuilds work without external APIs

You own your infrastructure completely. And it's all in Git.

---

## Next Steps

1. **Prepare configuration** (10 mins)
2. **Flash USB sticks** (20 mins)
3. **Deploy cluster** (30 mins total)
4. **Verify services** (5 mins)
5. **Restore data** (varies, largest is Immich @ 40GB)
6. **Move to Gitea** (5 mins)

Then: Enjoy your home lab. Everything is versioned, backed up, and reproducible.

---

## Questions?

See GIT-FIRST-WORKFLOW.md for the DevOps workflow and best practices.
