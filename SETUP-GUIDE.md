# Homelab Kubernetes Deployment Guide

> **⚠️ Work in Progress** — This documentation is actively being refined. Examples and details may change.

Complete step-by-step guide to deploying a self-hosted Kubernetes cluster with six integrated services.

---

## Before You Start

### System Requirements

**Hardware:**
- 3 servers with:
  - Multi-core CPU (4+ cores recommended)
  - 16GB+ RAM per node (tested with 26GB)
  - 500GB+ storage per node (recommend 1TB+)
  - Network connectivity

**Software on deployment machine:**
- Linux (Ubuntu 24.04 LTS, Debian 12, Fedora 40, or equivalent)
- Git
- Text editor (nano, vim, etc.)
- SSH client
- ~2GB free space for ISO files

**Accounts:**
- Tailscale (free tier)
- GitHub (for private repository)

### Estimated Timeline

- **Preparation:** 1-2 hours
- **OS installation:** 30 minutes
- **Cluster deployment:** 30-45 minutes
- **Service deployment:** 10 minutes
- **Total:** ~2-3 hours hands-on time

---

## Step 1: Repository Setup

### Clone the Repository

```bash
git clone https://github.com/yourname/homelab-infra.git
cd homelab-infra
```

### Create Local Configuration Files

```bash
# Create your local inventory (never committed to Git)
cp ansible/inventory/hosts.yml.example ansible/inventory/hosts.yml
nano ansible/inventory/hosts.yml
```

**Edit with your node details:**
```yaml
all:
  children:
    control_plane:
      hosts:
        cp-01:
          ansible_host: 192.168.X.X      # Your control plane IP
          tailscale_hostname: cp-01
    workers:
      hosts:
        worker-01:
          ansible_host: 192.168.X.X      # Your worker 1 IP
          tailscale_hostname: worker-01
        worker-02:
          ansible_host: 192.168.X.X      # Your worker 2 IP
          tailscale_hostname: worker-02
```

### Create OS Installation Configs

```bash
# Copy and customize each node
cp autoinstall/cp-01/user-data.example autoinstall/cp-01/user-data
nano autoinstall/cp-01/user-data

# Repeat for workers
cp autoinstall/worker-01/user-data.example autoinstall/worker-01/user-data
nano autoinstall/worker-01/user-data

cp autoinstall/worker-02/user-data.example autoinstall/worker-02/user-data
nano autoinstall/worker-02/user-data
```

**Key values to customize in each user-data file:**

| Field | What to set |
|---|---|
| `addresses` | Your node's static IP (e.g., `192.168.1.10/24`) |
| `gateway4` | Your network gateway (e.g., `192.168.1.1`) |
| `hostname` | Node name (cp-01, worker-01, worker-02) |
| `password` | Hashed root password (see below) |
| `authorized-keys` | Your SSH public key (see below) |
| `eno1` (or your NIC) | Your network interface name |

**Generate hashed password:**
```bash
echo "your-password" | mkpasswd --method=SHA-512 --stdin
# Copy the output into the password field
```

**Get your SSH public key:**
```bash
cat ~/.ssh/id_ed25519.pub
# If file doesn't exist, generate one:
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N ""
```

---

## Step 2: Prepare Installation Media

### Download Ubuntu 24.04 LTS

```bash
cd ~/downloads  # or wherever you store ISOs
wget https://releases.ubuntu.com/24.04/ubuntu-24.04-live-server-amd64.iso
```

### Create Bootable USB Sticks

**Using Ventoy (recommended):**

1. Install Ventoy: https://www.ventoy.net/en/download.html
2. Format USB stick with Ventoy
3. Copy Ubuntu ISO to USB: `cp ubuntu-24.04-live-server-amd64.iso /mnt/ventoy/`
4. Copy autoinstall configs: `cp -r autoinstall /mnt/ventoy/`
5. Eject and boot from USB

**Using Balena Etcher:**

1. Download Balena Etcher: https://www.balena.io/etcher/
2. Select ISO → Select USB → Flash
3. Manually copy autoinstall folder to USB after flashing

**Note:** You need 3 separate USB sticks or the ability to modify boot parameters for each node.

---

## Step 3: Install Operating System

### Boot Each Node

1. Insert USB stick into node
2. Power on and press F9 (or appropriate boot key) to boot menu
3. Select USB device
4. System boots into Ubuntu installer

### Autoinstall Process

- Ubuntu reads the autoinstall config from USB
- Installation runs automatically (~10 minutes)
- Node reboots into fresh Ubuntu 24.04 LTS
- **No user interaction required**

### Verify Installation

```bash
# After node boots
# SSH should work immediately if key is correct
ssh homelab@<node-ip>
```

**Repeat for all 3 nodes before proceeding.**

---

## Step 4: Deploy Kubernetes Cluster

### Get Tailscale Auth Key

1. Go to https://login.tailscale.com/admin/settings/keys
2. Click "Create auth key"
3. Make it **reusable** and **pre-approved**
4. Copy the token

### Run Deployment

From your deployment machine:

```bash
cd homelab-infra

# Phase 1: OS setup (Tailscale, SSH hardening, k8s prereqs)
TS_AUTHKEY=tskey-auth-xxxxx ./deploy.sh os

# Wait for completion (should see all nodes getting Tailscale IPs)

# Verify Tailscale is working
ansible k8s_nodes -i ansible/inventory/hosts.yml -m command -a "tailscale status"

# Phase 2: Kubernetes bootstrap
./deploy.sh bootstrap

# Phase 2b: Install cluster add-ons
./deploy.sh addons

# Phase 3: Deploy services
./deploy.sh services

# Verify cluster health
./deploy.sh verify
```

### Monitor Progress

Each phase includes status output. Monitor pod startup:

```bash
# In another terminal
watch kubectl get pods -A
```

---

## Step 5: Verify Services

### Check Cluster Health

```bash
# All nodes should be Ready
kubectl get nodes

# All pods should be Running (or Completed)
kubectl get pods -A

# Check ingress
kubectl get ingress -A

# Check certificates (should be True)
kubectl get certificate -A
```

### Access Services

All services are accessible via Tailscale DNS. In your Tailscale admin console:

1. Go to DNS settings
2. Add Pi-hole as a nameserver
3. Enable "Override local DNS"
4. All devices on your tailnet now use your cluster's DNS

**Access service URLs:**
```
https://vaultwarden.yourdomain.ts.net      # Passwords
https://gitea.yourdomain.ts.net            # Git repos
https://nextcloud.yourdomain.ts.net        # Files
https://immich.yourdomain.ts.net           # Photos
https://audiobookshelf.yourdomain.ts.net   # Audiobooks
https://pihole.yourdomain.ts.net/admin     # DNS settings
```

---

## Step 6: Configure Services

### Pi-hole

1. Go to https://pihole.yourdomain.ts.net/admin
2. Set admin password
3. Customize blocklists as desired
4. Your tailnet now uses this Pi-hole for DNS

### Gitea

1. Go to https://gitea.yourdomain.ts.net
2. Create first admin user
3. Configure repositories
4. Later: This becomes your production Git (push from GitHub)

### Vaultwarden

1. Go to https://vaultwarden.yourdomain.ts.net
2. Create account
3. Import passwords if you have backups

### Nextcloud

1. Go to https://nextcloud.yourdomain.ts.net
2. Create admin account
3. Configure storage locations

### Immich

1. Go to https://immich.yourdomain.ts.net
2. Create admin account
3. Set up library
4. ML processing starts automatically for existing photos

### Audiobookshelf

1. Go to https://audiobookshelf.yourdomain.ts.net
2. Create admin account
3. Point to audiobook library location

---

## Step 7: Migrate to Gitea (Production)

Once cluster is running and Gitea is accessible:

```bash
# Add Gitea as a new Git remote
git remote add gitea https://gitea.yourdomain.ts.net/homelab/homelab-infra.git

# Push your complete configuration to Gitea
git push gitea main

# (Optional) Remove GitHub remote if no longer needed
git remote remove origin

# Verify Gitea is the only remote
git remote -v
```

Now your cluster configuration lives in your self-hosted Gitea. GitHub can be archived.

---

## Troubleshooting

### SSH to Nodes Fails

**If Phase 1 hasn't completed yet:**
```bash
# Use IP directly (before Tailscale is up)
ssh -i ~/.ssh/id_ed25519 homelab@192.168.X.X
```

**After Phase 1:**
```bash
# Use Tailscale SSH (identity-based, no key needed)
ssh homelab@cp-01
```

**Error: "Could not resolve hostname"**
- Verify node IP in `ansible/inventory/hosts.yml`
- Verify node is on the same network
- Verify SSH key is correct in autoinstall config

### Ansible Connection Refused

```bash
# Check node is reachable
ping 192.168.X.X

# Check SSH is working
ssh homelab@192.168.X.X

# If using Tailscale IP, verify tailscaled is running on node
ssh homelab@192.168.X.X "systemctl status tailscaled"
```

### Pod Not Starting

```bash
# Check pod status
kubectl describe pod <pod-name> -n <namespace>

# Check logs
kubectl logs <pod-name> -n <namespace>

# Check node has resources
kubectl top nodes
kubectl top pods -A
```

### Storage Not Working

```bash
# Check storage classes
kubectl get storageclass

# Check PVCs
kubectl get pvc -A

# Check Longhorn status
kubectl get nodes -n longhorn-system
```

---

## Next Steps

### Update Management

Regular updates keep your cluster secure:

```bash
# Check for available updates
./deploy.sh updates-check

# Setup weekly automated checks
./deploy.sh updates-cron

# Upgrade Kubernetes (when ready)
K8S_VERSION=v1.31 ./deploy.sh k8s-upgrade
```

See `docs/UPDATE-MANAGEMENT.md` for complete update strategy.

### Monitoring & Observability

Add monitoring to watch cluster health:

```bash
# Install Prometheus + Grafana (future enhancement)
# See docs/MONITORING.md when available
```

### Backup Strategy

Regular backups protect against data loss:

```bash
# Longhorn has built-in snapshots
# local-path storage should be backed up externally
# Databases (Postgres) should be dumped regularly
```

See `docs/BACKUP-STRATEGY.md` when available.

---

## Performance Tips

### For Small Hardware
- Reduce service replicas if low on memory
- Use local-path instead of Longhorn for non-critical data
- Monitor resource usage: `kubectl top pods -A`

### For Better Performance
- Use fast NVMe storage
- Increase RAM if possible
- Monitor Longhorn disk I/O: `kubectl logs -n longhorn-system -l app=longhorn-manager`

---

## Disaster Recovery

If the cluster fails completely:

```bash
# The entire infrastructure is in Git
git clone https://gitea.yourdomain.ts.net/homelab/homelab-infra.git
cd homelab-infra

# Restore local configs (keep them safe separately)
cp /backup/hosts.yml ansible/inventory/
cp /backup/user-data autoinstall/cp-01/
# ... etc

# Redeploy from scratch
TS_AUTHKEY=xxx ./deploy.sh all
```

**Always keep backups of:**
- `ansible/inventory/hosts.yml`
- `autoinstall/*/user-data`
- Service data (Nextcloud, Immich, Gitea repos)

---

## Common Issues & Solutions

| Issue | Solution |
|---|---|
| "Permission denied" SSH | Check SSH key in autoinstall config |
| Nodes on different subnets | Use Tailscale routing or ensure network connectivity |
| Disk space issues | Monitor with `df -h`, add storage to nodes |
| Services not responsive | Check pods: `kubectl get pods -A` |
| Ingress not working | Check ingress controller: `kubectl get pods -n ingress-nginx` |
| Certificates not issuing | Check cert-manager: `kubectl logs -n cert-manager` |

---

## Getting Help

- Check logs: `kubectl logs -n <namespace> <pod-name>`
- Check events: `kubectl get events -A`
- Check node status: `kubectl describe node <node-name>`
- Review Ansible output for detailed error messages

---

## Contributing

Found an issue or have an improvement? Contributions welcome!

1. Fork the repository
2. Create a feature branch
3. Test your changes
4. Submit a pull request

---

## License

MIT License — See LICENSE file for details.

---

**⚠️ This is a work-in-progress project. Test thoroughly before deploying critical workloads.**

Last updated: June 2025
