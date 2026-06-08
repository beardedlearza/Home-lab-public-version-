# Git-First Workflow: Using GitHub as Bootstrap, Gitea as Production

This is a **DevOps-first approach** where your entire infrastructure lives in Git, versioned and audited.

---

## Phase 0: GitHub Bootstrap (Temporary Staging)

Your infrastructure code starts on GitHub as a private repository. This is **temporary staging** — once Gitea is running on your cluster, GitHub can be archived.

### 1. Create private GitHub repo

```
Repository: github.com/yourname/homelab-infra (PRIVATE)
```

### 2. Initial setup

```bash
git clone https://github.com/yourname/homelab-infra.git
cd homelab-infra

# Copy example files and customize with YOUR values
cp ansible/inventory/hosts.yml.example ansible/inventory/hosts.yml
cp autoinstall/cp-01/user-data.example autoinstall/cp-01/user-data
# ... edit with your IPs, passwords, SSH keys

# First commit
git add .
git commit -m "Initial commit: Customize with real IPs and passwords"
git push origin main
```

---

## Phase 1-3: Deploy Cluster from GitHub

```bash
# All your deployment scripts run locally
TS_AUTHKEY=xxx ./deploy.sh os
./deploy.sh bootstrap
./deploy.sh addons
./deploy.sh services
```

---

## Phase 4: Migrate to Gitea (Production)

Once Gitea is running on your cluster:

### 1. Add Gitea as new remote

```bash
git remote add gitea https://gitea.yourdomain.ts.net/homelab/homelab-infra.git
```

### 2. Push to Gitea

```bash
git push gitea main
```

### 3. Remove GitHub remote (optional)

```bash
git remote remove origin
# Now gitea is your only remote
```

---

## From Now On: Pure Gitea

All changes flow through Gitea, which lives in your tailnet:

```bash
# Clone from Gitea (not GitHub)
git clone https://gitea.yourdomain.ts.net/homelab/homelab-infra.git

# Make changes, commit, push to Gitea
git add .
git commit -m "Update immich to latest image"
git push gitea main

# Deploy (or use GitOps with Gitea Actions)
kubectl apply -f k8s/services/immich.yaml
```

---

## File Structure: Safe for Public GitHub

**GitHub has only safe templates:**
- `ansible/inventory/hosts.yml.example` (no real IPs)
- `autoinstall/*/user-data.example` (no passwords)
- All playbooks, roles, manifests
- Documentation

**Your sensitive files stay local and gitignored:**
- `ansible/inventory/hosts.yml` (your real IPs)
- `autoinstall/*/user-data` (your passwords)
- Kubeconfig files
- Any backup data

See `.gitignore` for the full list.

---

## Disaster Recovery: The whole point of Git

If your entire cluster fails:

```bash
# Get latest from Gitea
git clone https://gitea.yourdomain.ts.net/homelab/homelab-infra.git
cd homelab-infra

# Rebuild in sequence
TS_AUTHKEY=xxx ./deploy.sh os
./deploy.sh bootstrap
./deploy.sh addons
./deploy.sh services

# Restore your data from backups (kept separately)
./scripts/restore-nextcloud.sh /backup/nextcloud.tar
./scripts/restore-gitea.sh /backup/gitea.tar
./scripts/setup-immich-library.sh /backup/immich-library
```

**You're back online.**

---

## Why This Approach?

1. **GitHub = Bootstrap only** — simple, no long-term dependency
2. **Gitea = Production** — your code never leaves your infrastructure
3. **Git = Audit trail** — every change is tracked and reversible
4. **Reproducible** — entire cluster from `git clone`
5. **DevOps mindset** — infrastructure as code, versioned and tested

---

## Optional: Gitea Actions for CI/CD

Once comfortable, add `.gitea/workflows/deploy.yml`:

```yaml
name: Deploy on Push
on: [push]
jobs:
  deploy:
    runs-on: docker
    steps:
      - uses: actions/checkout@v3
      - name: Deploy services
        run: kubectl apply -f k8s/
```

Now pushing to Gitea automatically deploys to your cluster. This is real DevOps.

---

## The Three Git Remotes Pattern

**Day 1-3 (Bootstrap):**
```
Local → GitHub (staging)
```

**Day 4+ (Production):**
```
Local → Gitea (production) ← GitHub archived
```

**Disaster recovery:**
```
Gitea → New machine → Rebuild cluster
```

Simple, safe, and entirely within your control.
