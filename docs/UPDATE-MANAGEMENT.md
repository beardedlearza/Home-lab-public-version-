# Update Management Guide

Your homelab uses a **layered update strategy**: automatic where safe, manual where it matters.

---

## Update Layers & Strategy

### Layer 1: OS Security (AUTOMATIC)
**What:** Ubuntu 24.04 security patches  
**Frequency:** Daily (automatic)  
**Tool:** `unattended-upgrades`

**What gets updated:**
- Security patches (CVEs, vulnerabilities)
- Bug fixes
- Ubuntu system updates

**What's excluded:**
- kubeadm, kubelet, kubectl (manual control)
- containerd.io (safe to auto-update, but blacklisted by default)
- Kernel major versions (manual)

**How to monitor:**
```bash
# SSH to any node
ssh homelab@cp-01

# Check logs
sudo tail -f /var/log/unattended-upgrades/unattended-upgrades.log

# Or use Ansible to check all nodes
ansible-playbook -i ansible/inventory/hosts.yml ansible/updates-auto.yml
```

---

### Layer 2: Container Runtime (AUTOMATIC)
**What:** containerd updates  
**Frequency:** Monthly (can auto-update)  
**Status:** Currently blacklisted (you control it)

**To enable auto-update of containerd:**
```bash
# Edit ansible/group_vars/all.yml
# Remove 'containerd.io' from unattended_upgrades_blacklist

# Re-apply Ansible
ansible-playbook -i ansible/inventory/hosts.yml ansible/site.yml
```

---

### Layer 3: Kubernetes (MANUAL, Coordinated)
**What:** kubeadm, kubelet, kubectl  
**Frequency:** 1-2 times per year  
**Tools:** `k8s-upgrade.yml` playbook

**Why manual?**
- Requires coordination (control plane first, then workers)
- Need to drain/uncordon nodes properly
- Breaking changes between versions
- Must test before production

**How to upgrade:**

```bash
# Step 1: Check current version
kubectl version --short

# Step 2: See what versions are available
ansible-playbook -i ansible/inventory/hosts.yml \
  ansible/k8s-upgrade.yml -e upgrade_action=check

# Step 3: Plan the upgrade (shows impact)
ansible-playbook -i ansible/inventory/hosts.yml \
  ansible/k8s-upgrade.yml \
  -e upgrade_action=plan \
  -e target_version=v1.31

# Step 4: Execute upgrade (REQUIRES CONFIRMATION)
ansible-playbook -i ansible/inventory/hosts.yml \
  ansible/k8s-upgrade.yml \
  -e upgrade_action=upgrade \
  -e target_version=v1.31

# Step 5: Verify
kubectl get nodes  # All should be Ready with new version
kubectl get pods -A  # All should be Running
```

**Kubernetes upgrade process (what the playbook does):**
1. Upgrade kubeadm on control plane
2. Run `kubeadm upgrade apply`
3. Drain & upgrade kubelet on control plane
4. **For each worker (one at a time):**
   - Drain the worker
   - Upgrade kubeadm & kubelet
   - Uncordon (bring back online)
5. Verify cluster health

---

### Layer 4: Helm Charts (SEMI-AUTO)
**What:** Longhorn, MetalLB, ingress-nginx, cert-manager  
**Frequency:** 2-4 times per year  
**Tools:** `helm-updates.yml` playbook

**How to check for updates:**

```bash
# Check what's available (no changes)
ansible-playbook -i ansible/inventory/hosts.yml \
  ansible/helm-updates.yml -e helm_action=check
```

Output shows:
```
Longhorn:     v1.5.3 → v1.6.0 (⚠ Update available)
MetalLB:      v0.13.1 → v0.14.0 (⚠ Update available)
ingress-nginx: v1.8.0 → v1.9.0 (⚠ Update available)
cert-manager:  v1.13.0 → v1.14.0 (⚠ Update available)
```

**To generate upgrade commands (preview):**

```bash
ansible-playbook -i ansible/inventory/hosts.yml \
  ansible/helm-updates.yml -e helm_action=generate

# Shows the commands that will run
cat /tmp/helm-upgrades.sh
```

**To execute upgrades:**

```bash
ansible-playbook -i ansible/inventory/hosts.yml \
  ansible/helm-updates.yml -e helm_action=upgrade
```

---

### Layer 5: Service Deployments (MANUAL)
**What:** Immich, Gitea, Nextcloud, etc. (image tags)  
**Frequency:** As needed (security patches or new features)  
**Tools:** kubectl + Git

**How to update a service:**

```bash
# 1. Edit the manifest
nano k8s/services/immich.yaml

# Change the image tag
# FROM: image: ghcr.io/immich-app/immich-server:latest
# TO:   image: ghcr.io/immich-app/immich-server:v1.99.0

# 2. Apply the change
kubectl apply -f k8s/services/immich.yaml

# 3. Watch the rollout
kubectl rollout status deployment/immich -n immich --timeout=5m

# 4. Commit to Git (audit trail)
git add k8s/services/immich.yaml
git commit -m "Update Immich to v1.99.0"
git push gitea main
```

**Pinning image tags:**
- Use specific versions (v1.99.0) not `latest`
- Gives you control & audit trail
- Easier to rollback if needed

---

## Automated Update Checking

**Setup automated weekly update checks:**

```bash
ansible-playbook -i ansible/inventory/hosts.yml \
  ansible/updates-cron-setup.yml
```

This installs a cron job that runs every Sunday at 2 AM and:
- Checks for OS security updates
- Reports Kubernetes available versions
- Lists available Helm chart updates
- Logs to `/var/log/homelab-updates/`

**View update logs:**

```bash
ssh homelab@cp-01
tail -f /var/log/homelab-updates/*.log
```

---

## Update Schedule Recommendation

| When | What | How |
|---|---|---|
| **Daily** | OS patches | Automatic (unattended-upgrades) |
| **Weekly** | Check all layers | `ansible-playbook ansible/updates-auto.yml` |
| **Monthly** | Review Helm charts | `ansible-playbook ansible/helm-updates.yml -e helm_action=check` |
| **Service updates** | As-needed | Edit image tags, `kubectl apply`, commit to Git |
| **Spring & Fall** | Kubernetes upgrade | `ansible-playbook ansible/k8s-upgrade.yml -e target_version=vX.Y` |
| **Annually** | Ubuntu LTS upgrade | Major undertaking, do in maintenance window |

---

## The Git Audit Trail

All update changes go through Git for traceability:

```bash
# See all updates made
git log --oneline

# View what changed in an update
git show <commit-hash>

# Rollback if needed
git revert <commit-hash>
```

Example:
```
abc1234 Update Immich to v1.99.0
def5678 Update ingress-nginx via Helm
ghi9012 Upgrade Kubernetes to v1.30
```

---

## Rollback Procedures

### If a Kubernetes upgrade fails:
```bash
# This is why we use kubeadm — etcd is backed up automatically
# Rollback is relatively safe

# Reset the node
ssh homelab@worker-01
sudo kubeadm reset

# Rejoin with previous version
kubeadm join <control-plane-ip>:6443 --token <token> --discovery-token-ca-cert-hash sha256:...
```

### If a Helm chart upgrade breaks things:
```bash
# Helm keeps release history
helm history <release-name> -n <namespace>

# Rollback to previous version
helm rollback <release-name> -n <namespace> <revision>
```

### If a service deployment breaks:
```bash
# Git has the previous manifest
git revert <commit-hash>
kubectl apply -f k8s/services/<service>.yaml
```

---

## Monitoring Updates

**Key things to monitor:**

```bash
# OS security patches (should be 0 if auto-update working)
ssh homelab@cp-01
sudo apt-get upgrade -s | grep -i security

# Kubernetes component status
kubectl get componentstatuses

# Node status
kubectl get nodes -o wide

# Pod status
kubectl get pods -A

# Helm release status
helm list -A
```

---

## Alerting (Optional, Future)

Once you want notifications about updates:

```bash
# Install Prometheus + AlertManager
helm install alertmanager prometheus-community/kube-prometheus-stack \
  -n monitoring --create-namespace

# Configure alerts for:
# - Node NotReady
# - Pod CrashLooping
# - Certificate expiry
# - Storage usage
```

---

## Summary

| Layer | Automatic? | Frequency | Control |
|---|---|---|---|
| OS Security | ✅ Yes | Daily | Blacklist in `group_vars/all.yml` |
| Container Runtime | ⚠️ Blacklisted | Monthly | Enable in `group_vars/all.yml` |
| Kubernetes | ❌ Manual | 1-2x/year | `k8s-upgrade.yml` playbook |
| Helm Charts | ⚠️ Check only | 2-4x/year | `helm-updates.yml` playbook |
| Services | ❌ Manual | As-needed | Edit YAML, commit to Git |

**You stay in control of what matters. Automation handles the rest.**
