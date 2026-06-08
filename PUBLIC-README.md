# Homelab Kubernetes Cluster — Open Source Infrastructure as Code

> **⚠️ Work in Progress** — This project is actively being developed. Features, documentation, and examples may change. Not production-ready for critical workloads.

A **Git-first, DevOps-ready** home lab built with infrastructure-as-code principles. Deploy a complete Kubernetes cluster with six self-hosted services on commodity hardware using Ansible automation.

## Overview

**Architecture:**
- **3 nodes** running Kubernetes 1.30+ (kubeadm)
- **Ubuntu 24.04 LTS** with automated deployment
- **Tailscale** mesh networking (no port forwarding)
- **Flannel** CNI overlay network
- **Longhorn** distributed storage + local-path provisioner
- **Six self-hosted services:**
  - Pi-hole (DNS ad-blocker)
  - Vaultwarden (password manager)
  - Gitea (self-hosted Git)
  - Nextcloud (file sync)
  - Immich (photo library with ML)
  - Audiobookshelf (audiobooks/podcasts)

**Key Features:**
- ✅ Fully automated deployment (Ansible + kubeadm)
- ✅ Git-based version control (GitHub staging → Gitea production)
- ✅ Tailscale SSH (no SSH key distribution)
- ✅ Self-hosted everything (no external dependencies)
- ✅ Disaster recovery via Git (`git clone` → rebuild in 30 mins)
- ✅ Automated updates (security patches + manual control for critical components)

---

## Prerequisites

### Hardware
- 3 commodity servers (tested with HP EliteDesk 800 G2 Mini equivalent)
- 26GB+ RAM per node
- 1-2TB NVMe storage per node
- Network connectivity (same or adjacent subnets)

### Software & Accounts
- Linux deployment machine (Ubuntu 24.04 LTS, Debian 12, or Fedora 40 recommended)
- Git installed locally
- Ansible 2.9+
- kubectl, Helm (optional, for manual management)
- Tailscale account (free tier sufficient)
- GitHub account (for private bootstrap repository)

### Knowledge
- Basic Linux/command-line familiarity
- Understanding of Kubernetes concepts (helpful, not required)
- Git workflow basics

---

## Quick Start

### 1. Clone This Repository

```bash
git clone https://github.com/yourname/homelab-infra.git
cd homelab-infra
```

### 2. Customize Configuration

Copy example files and edit with your environment details:

```bash
# Network configuration
cp ansible/inventory/hosts.yml.example ansible/inventory/hosts.yml
nano ansible/inventory/hosts.yml

# OS installation configs
cp autoinstall/cp-01/user-data.example autoinstall/cp-01/user-data
cp autoinstall/worker-01/user-data.example autoinstall/worker-01/user-data
cp autoinstall/worker-02/user-data.example autoinstall/worker-02/user-data
nano autoinstall/cp-01/user-data
nano autoinstall/worker-01/user-data
nano autoinstall/worker-02/user-data
```

**What to customize:**
- Node hostnames and IP addresses
- SSH public key for bootstrap access
- System timezone
- Tailscale configuration

### 3. Prepare Nodes

Create bootable Ubuntu 24.04 LTS installation media with cloud-init autoinstall:

```bash
# Download Ubuntu ISO
wget https://releases.ubuntu.com/24.04/ubuntu-24.04-live-server-amd64.iso

# Flash to USB with Ventoy or Balena Etcher
# Include autoinstall/ folder on the USB for automated setup
```

Boot each node from the USB — installation is fully automated (~10 minutes per node).

### 4. Deploy Cluster

From your deployment machine (on same network as nodes):

```bash
# Get Tailscale reusable auth key
# https://login.tailscale.com/admin/settings/keys

# Run full deployment (all phases)
TS_AUTHKEY=tskey-auth-xxx ./deploy.sh all

# Or phase by phase
TS_AUTHKEY=tskey-auth-xxx ./deploy.sh os      # Phase 1: OS setup
./deploy.sh bootstrap                          # Phase 2: Kubernetes
./deploy.sh addons                             # Phase 2b: Add-ons
./deploy.sh services                           # Phase 3: Services
./deploy.sh verify                             # Health check
```

### 5. Verify & Access

```bash
# Check cluster status
kubectl get nodes
kubectl get pods -A

# Access services over Tailscale
https://vaultwarden.yourdomain.ts.net
https://gitea.yourdomain.ts.net
https://nextcloud.yourdomain.ts.net
# ... etc
```

---

## Deployment Phases

### Phase 1: OS Setup
- Installs Ubuntu 24.04 LTS
- Configures networking and hostname
- Hardens SSH (key-only, Tailscale SSH enabled)
- Installs Kubernetes prerequisites (containerd, kubeadm, kubelet)
- Enables automatic security updates
- **Duration:** ~5 minutes per node (automated via cloud-init)
- **Run from:** Deployment machine
- **Command:** `TS_AUTHKEY=xxx ./deploy.sh os`

### Phase 2: Kubernetes Bootstrap
- Initializes control plane (kubeadm init)
- Installs Flannel CNI
- Joins worker nodes to cluster
- **Duration:** ~10 minutes total
- **Run from:** Deployment machine
- **Command:** `./deploy.sh bootstrap`

### Phase 2b: Cluster Add-ons
- Installs Longhorn (distributed storage)
- Installs local-path provisioner (node-local storage)
- Installs MetalLB (bare-metal load balancer)
- Installs ingress-nginx (TLS + hostname routing)
- Installs cert-manager (automatic TLS certificates)
- **Duration:** ~5-10 minutes
- **Run from:** Deployment machine
- **Command:** `./deploy.sh addons`

### Phase 3: Service Deployment
- Creates Kubernetes namespaces
- Deploys all six services (Gitea, Nextcloud, Immich, etc.)
- Configures ingress routing and TLS
- **Duration:** ~2 minutes (pod startup varies by service)
- **Run from:** Deployment machine
- **Command:** `./deploy.sh services`

### Phase 4: Data Restoration
- Restore backups of existing services
- Done manually with provided scripts
- **Duration:** Varies (large datasets may take hours)

---

## File Structure

```
homelab-infra/
├── .gitignore                          # Protects sensitive local configs
├── README.md                           # This file
├── GIT-FIRST-WORKFLOW.md               # Git strategy (GitHub → Gitea)
├── deploy.sh                           # Main orchestration script
│
├── autoinstall/                        # Ubuntu cloud-init configs
│   ├── cp-01/
│   │   ├── user-data.example          # Template (in Git)
│   │   ├── user-data                  # Your config (gitignored)
│   │   └── meta-data
│   ├── worker-01/
│   └── worker-02/
│
├── ansible/                            # Infrastructure automation
│   ├── site.yml                        # Phase 1: OS setup
│   ├── k8s-bootstrap.yml               # Phase 2: Kubernetes
│   ├── k8s-install-addons.yml          # Phase 2b: Add-ons
│   ├── k8s-upgrade.yml                 # Kubernetes upgrade automation
│   ├── helm-updates.yml                # Helm chart updates
│   ├── updates-auto.yml                # Update status monitoring
│   ├── updates-cron-setup.yml          # Automated update checks
│   │
│   ├── inventory/
│   │   ├── hosts.yml.example           # Template
│   │   └── hosts.yml                   # Your IPs (gitignored)
│   ├── group_vars/
│   │   └── all.yml                     # Global settings
│   └── roles/
│       ├── base/                       # OS hardening + Tailscale
│       ├── containerd/                 # Container runtime
│       ├── kubernetes-common/          # K8s packages
│       └── kubeadm/                    # Control plane init
│
├── k8s/                                # Kubernetes manifests
│   ├── base/
│   │   ├── namespaces.yaml
│   │   ├── storage-classes.yaml
│   │   └── ingress.yaml                # TLS + routing
│   └── services/
│       └── README.md                   # Service deployment guide
│
├── docs/
│   └── UPDATE-MANAGEMENT.md            # Update strategy guide
│
└── scripts/
    ├── restore-nextcloud.sh
    ├── restore-gitea.sh
    └── setup-immich-library.sh
```

---

## Key Concepts

### Git-First Workflow

**GitHub (Bootstrap):**
- Safe templates only (no real credentials)
- Staging ground for your infrastructure code
- Shareable and reviewable

**Gitea (Production):**
- Runs on your cluster
- Contains complete working configs (credentials + code)
- Only accessible via your tailnet (private)
- Single source of truth after cluster is running

**Flow:**
```
GitHub (safe templates)
    ↓ (clone + customize locally)
Desktop (local configs + sensitive data)
    ↓ (deploy cluster)
Gitea (on cluster, production)
    ↓ (everything lives here afterwards)
```

### Sensitive Data Protection

Sensitive files are **never committed to Git**:

```
.gitignore blocks:
- ansible/inventory/hosts.yml (your IPs)
- autoinstall/*/user-data (your passwords)
- k8s/services/*.yaml (if you customize)
- *.key, *.pem (credentials)
- kubeconfig files
```

Safe templates ARE committed:
```
GitHub contains:
- ansible/inventory/hosts.yml.example
- autoinstall/*/user-data.example
- All playbooks, manifests, scripts
```

### Tailscale Networking

All services are accessed via Tailscale's private mesh network:

```
Your Desktop (tailnet)
    ↓ (Tailscale VPN)
Cluster Services (tailnet)
    ↓
Example URLs:
- https://vaultwarden.yourdomain.ts.net
- https://gitea.yourdomain.ts.net
- https://nextcloud.yourdomain.ts.net
```

**Benefits:**
- No port forwarding required
- No dynamic DNS needed
- End-to-end encrypted
- Works across different physical networks/VLANs

### Ansible Automation

Ansible playbooks automate the entire deployment:

```bash
# Reads your local inventory
ansible-playbook -i ansible/inventory/hosts.yml ansible/site.yml

# Knows which nodes to target from hosts.yml
# Runs commands over SSH
# Idempotent (safe to run multiple times)
# Reports success/failure
```

---

## Update Management

The cluster has a **layered update strategy**:

| Layer | Auto? | Frequency | Control |
|---|---|---|---|
| OS Security | ✅ Yes | Daily | `unattended-upgrades` |
| Container Runtime | ⚠️ Blacklisted | Monthly | Manual via Ansible |
| Kubernetes | ❌ Manual | 1-2x/year | `k8s-upgrade.yml` playbook |
| Helm Charts | ⚠️ Check only | 2-4x/year | `helm-updates.yml` playbook |
| Services | ❌ Manual | As-needed | Edit YAML + `kubectl apply` |

**Check for updates:**
```bash
./deploy.sh updates-check
```

**Setup automated weekly checks:**
```bash
./deploy.sh updates-cron
```

**Kubernetes upgrade (manual, requires confirmation):**
```bash
K8S_VERSION=v1.31 ./deploy.sh k8s-upgrade
```

See `docs/UPDATE-MANAGEMENT.md` for complete strategy.

---

## Services Included

### Pi-hole
- DNS-level ad blocking
- Accessible via Tailscale DNS
- Automatic blocking for all devices on tailnet

### Vaultwarden
- Self-hosted password manager
- SQLite backend with Longhorn backup
- HTTPS via cert-manager

### Gitea
- Self-hosted Git repository server
- Markdown support, issue tracking
- Postgres backend (shared with Nextcloud)
- **This becomes your production Git after cluster setup**

### Nextcloud
- File synchronization and sharing
- Photo gallery
- Calendar, contacts, tasks
- Postgres + Redis backend

### Immich
- Photo library with AI face recognition
- Mobile app support
- Duplicate detection
- Uses cluster resources for ML inference

### Audiobookshelf
- Audiobook and podcast server
- Mobile app support
- Library organization and tagging
- Metadata management

---

## Troubleshooting

### Nodes not connecting to cluster
```bash
# Check kubelet logs on the node
sudo journalctl -u kubelet -f

# Check kubeadm status
kubectl get nodes
kubectl describe node <node-name>
```

### PVC stuck in Pending
```bash
# Check storage class
kubectl get storageclass

# Check Longhorn status
kubectl logs -n longhorn-system -l app=longhorn-manager
```

### Services not accessible
```bash
# Check ingress
kubectl get ingress -A
kubectl describe ingress homelab-ingress -n ingress-nginx

# Check certificates
kubectl get certificate -A
```

### Tailscale SSH not working
```bash
# Verify SSH is enabled
tailscale status | grep SSH

# Re-enable if needed
sudo tailscale up --ssh
```

---

## Contributing

This is an open-source project. Contributions welcome:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/improvement`)
3. Make changes
4. Test in a non-production environment
5. Submit pull request

**Areas for contribution:**
- Alternate CNI options (Cilium, Calico)
- Additional services (monitoring, logging, etc.)
- Alternative container runtimes
- Security hardening
- Documentation improvements
- CI/CD pipeline setup

---

## Roadmap (Future)

- [ ] Prometheus + Grafana monitoring stack
- [ ] Loki log aggregation
- [ ] Sealed Secrets for credential management
- [ ] ArgoCD for GitOps deployments
- [ ] Backup automation (Velero)
- [ ] Network policies
- [ ] Pod security policies
- [ ] Multi-cluster federation
- [ ] Helm chart repositories
- [ ] Automated testing in CI/CD

---

## Limitations & Known Issues

- **Hardware-specific:** Designed for commodity x86-64 servers
- **Single cluster:** No HA control plane (3 nodes total)
- **Networking:** Assumes single L2 network or Tailscale bridging
- **Storage:** Longhorn requires etcd stability; single-replica volumes have no redundancy
- **Resource constraints:** Small nodes limit workload density
- **Documentation:** WIP — some areas may be incomplete
- **Testing:** Tested on specific hardware; results may vary

---

## Security Considerations

**What this project provides:**
- ✅ SSH key-based authentication
- ✅ Tailscale's end-to-end encryption
- ✅ Automatic TLS certificates
- ✅ Network isolation via Tailscale
- ✅ Firewall rules between services (network policies WIP)

**What you should add:**
- [ ] Network policies (Cilium or Calico)
- [ ] Pod security policies
- [ ] RBAC policies
- [ ] Secrets encryption at rest
- [ ] Regular backups off-cluster
- [ ] Security scanning of images
- [ ] Audit logging
- [ ] Rate limiting and DDoS protection

---

## License

This project is released under the **MIT License**. See LICENSE file for details.

You are free to use, modify, and distribute this code for personal or commercial use, with proper attribution.

---

## Support & Community

**Issues & Questions:**
- GitHub Issues: https://github.com/yourname/homelab-infra/issues
- Discussions: https://github.com/yourname/homelab-infra/discussions

**Related Projects:**
- [Kubernetes Docs](https://kubernetes.io/docs/)
- [Ansible Docs](https://docs.ansible.com/)
- [Tailscale Docs](https://tailscale.com/docs/)
- [Longhorn Docs](https://longhorn.io/docs/)

---

## Disclaimer

This is a hobby/home lab project. While efforts have been made to follow best practices:

- **Not production-ready** for critical workloads
- **Use at your own risk** — test thoroughly before deploying anything important
- **No warranties** — provided as-is
- **Security is your responsibility** — follow security best practices
- **Backup everything** — cluster failure is possible
- **Keep software updated** — stay on top of security patches

---

## Acknowledgments

Built with inspiration from:
- Kubernetes community and documentation
- Ansible best practices
- Home lab communities (r/homelab, etc.)
- Open-source projects (Gitea, Nextcloud, Immich, etc.)

---

**⚠️ This project is a work in progress. Features, documentation, and API may change without notice.**

Last updated: June 2025
