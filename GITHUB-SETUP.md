# GitHub Setup: Private Repository Bootstrap

This guide walks you through setting up a **private GitHub repository** that will auto-install and deploy your entire homelab infrastructure.

---

## Step 1: Create Private GitHub Repository

1. Go to https://github.com/new
2. **Repository name:** `homelab-infra`
3. **Description:** "Self-hosted Kubernetes cluster infrastructure"
4. **Visibility:** ✅ **Private** (only you can see it)
5. **Initialize with:** None (we'll push our files)
6. Click **Create repository**

You now have a private GitHub repo.

---

## Step 2: Initial Local Setup

On your Linux machine:

```bash
# Clone the empty repo
git clone https://github.com/yourname/homelab-infra.git
cd homelab-infra

# Copy all files from this package
cp -r /path/to/homelab/* .

# Copy example files and customize
cp ansible/inventory/hosts.yml.example ansible/inventory/hosts.yml
cp autoinstall/cp-01/user-data.example autoinstall/cp-01/user-data
cp autoinstall/worker-01/user-data.example autoinstall/worker-01/user-data
cp autoinstall/worker-02/user-data.example autoinstall/worker-02/user-data

# EDIT with your real values
nano ansible/inventory/hosts.yml
nano autoinstall/cp-01/user-data
nano autoinstall/worker-01/user-data
nano autoinstall/worker-02/user-data

# Commit to GitHub
git add .
git commit -m "Initial commit: homelab infrastructure as code"
git push origin main
```

---

## Step 3: Create GitHub Personal Access Token (for automation)

Later, when your homelab is running and you want to push from Gitea → GitHub as backup:

1. Go to https://github.com/settings/tokens
2. Click **Generate new token (classic)**
3. **Token name:** `homelab-gitea-sync`
4. **Expiration:** 90 days (or No expiration)
5. **Scopes:** Check `repo` (full control of private repositories)
6. Click **Generate token**
7. **Copy the token** — you won't see it again

Save this token securely (password manager or on paper). You'll use it to push from Gitea to GitHub.

---

## Step 4: (Optional) GitHub Actions for Automation

GitHub Actions can run workflows automatically. For now, you'll deploy manually from your machine:

```bash
# Initial bootstrap deploy from GitHub
git clone https://github.com/yourname/homelab-infra.git
cd homelab-infra

# Run deployment
TS_AUTHKEY=tskey-auth-xxx ./deploy.sh all
```

---

## Step 5: Once Gitea is Running (Migration)

When your cluster is up and Gitea is working:

### Add Gitea as new remote

```bash
git remote add gitea https://gitea.yourdomain.ts.net/homelab/homelab-infra.git
```

### Push to Gitea

```bash
git push gitea main
```

### (Optional) Setup GitHub ↔ Gitea Sync

You can keep GitHub as a backup and periodically sync Gitea → GitHub:

```bash
# On Gitea repo, push to GitHub as well
git remote set-url --add origin https://YOUR_TOKEN@github.com/yourname/homelab-infra.git

# Now pushing to origin pushes to both GitHub and Gitea
git push
```

---

## Repository Structure (What's in GitHub)

```
github.com/yourname/homelab-infra/
│
├── .gitignore                         ← Protects your sensitive files
├── README.md                          ← Main guide
├── GIT-FIRST-WORKFLOW.md             ← Git + DevOps philosophy
│
├── .github/workflows/                 ← GitHub Actions (optional)
│   └── deploy-on-push.yml            ← Auto-deploy when you push
│
├── autoinstall/
│   ├── cp-01/user-data.example       ← Safe template (no real data)
│   ├── cp-01/user-data               ← gitignored (your real IPs)
│   └── [worker configs]
│
├── ansible/                           ← All Ansible playbooks & roles
│   ├── site.yml
│   ├── k8s-bootstrap.yml
│   ├── k8s-upgrade.yml
│   ├── helm-updates.yml
│   ├── updates-auto.yml
│   └── [all roles]
│
├── k8s/                               ← Kubernetes manifests
│   ├── base/
│   └── services/
│
├── docs/                              ← Documentation
│   └── UPDATE-MANAGEMENT.md
│
└── scripts/                           ← Restoration scripts
    ├── restore-nextcloud.sh
    ├── restore-gitea.sh
    └── setup-immich-library.sh
```

---

## What Gets Pushed to GitHub (Safe)

✅ **Templates & code:**
- `autoinstall/*/user-data.example`
- All Ansible playbooks & roles
- All Kubernetes manifests
- Scripts
- Documentation

❌ **Never pushed (gitignored):**
- `autoinstall/*/user-data` (your passwords, SSH keys)
- `ansible/inventory/hosts.yml` (your real IPs)
- `kubeconfig` files
- Backup data
- `.vault-password` files

---

## Workflow: GitHub as Bootstrap, Gitea as Production

### Day 1-3: Bootstrap from GitHub

```bash
# Get the code
git clone https://github.com/yourname/homelab-infra.git

# Customize locally (sensitive files stay local)
cp ansible/inventory/hosts.yml.example ansible/inventory/hosts.yml
nano ansible/inventory/hosts.yml  # Your IPs (not pushed to GitHub)

# Deploy
TS_AUTHKEY=xxx ./deploy.sh all
```

### Day 4+: Move to Gitea (on your cluster)

```bash
# Once Gitea is running, add it as remote
git remote add gitea https://gitea.yourdomain.ts.net/homelab/homelab-infra.git

# Push your infrastructure to Gitea
git push gitea main

# (Optional) Keep GitHub as backup
git remote set-url --add origin https://TOKEN@github.com/yourname/homelab-infra.git
git push  # Pushes to both GitHub and Gitea
```

### Long-term: Gitea is the source of truth

```bash
# GitHub is now optional backup
# Gitea (on your infrastructure) is primary

# Clone from Gitea
git clone https://gitea.yourdomain.ts.net/homelab/homelab-infra.git

# All changes go through Gitea
git push gitea main

# GitHub stays in sync (optional)
git push origin main
```

---

## Quick Start Command Reference

```bash
# Setup
git clone https://github.com/yourname/homelab-infra.git
cd homelab-infra
cp ansible/inventory/hosts.yml.example ansible/inventory/hosts.yml
nano ansible/inventory/hosts.yml

# Deploy everything
TS_AUTHKEY=tskey-auth-xxx ./deploy.sh all

# Later: Check for updates
./deploy.sh updates-check

# Later: Upgrade Kubernetes
K8S_VERSION=v1.31 ./deploy.sh k8s-upgrade

# Later: Move to Gitea
git remote add gitea https://gitea.yourdomain.ts.net/homelab/homelab-infra.git
git push gitea main
```

---

## Security Notes

**GitHub is PRIVATE:**
- Only you can see the code
- GitHub can see it (read their privacy policy)
- Safe to store code, NOT sensitive credentials

**Your sensitive files (gitignored):**
- IPs, passwords, SSH keys stay LOCAL
- Never pushed to GitHub
- Gitea receives them only when you manually push code changes

**Example sensitive files you create locally:**
```
ansible/inventory/hosts.yml          ← Your real IPs
autoinstall/cp-01/user-data         ← Your passwords
autoinstall/worker-01/user-data     ← Your SSH key
autoinstall/worker-02/user-data     ← Your settings
kubeconfig                           ← Cluster certificate
```

All these are in `.gitignore` so they're never committed.

---

## GitHub Advanced: Actions (Optional, Future)

Once comfortable, you can add GitHub Actions to automatically:
- Run Ansible lint on pushes
- Validate Kubernetes manifests
- Test deployments (in a sandbox)
- Auto-deploy to your cluster (via Gitea)

Example: `.github/workflows/validate.yml`
```yaml
name: Validate Infrastructure
on: [push]
jobs:
  ansible-lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run ansible-lint
        run: ansible-lint ansible/
  k8s-validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Validate Kubernetes manifests
        run: |
          for f in k8s/**/*.yaml; do
            kubectl apply --dry-run=client -f $f
          done
```

This would validate your code every time you push to GitHub.

---

## Summary: Three-Repo Pattern

```
GitHub (Bootstrap & Backup)
    ↓
    │ git clone
    │ (Customize locally)
    ↓
Your Linux Machine (Customize, Deploy)
    ↓
    │ ./deploy.sh all
    │ (Cluster comes up with Gitea)
    ↓
Gitea on Your Cluster (Production Source of Truth)
    ↓
    │ git push gitea
    │ (Optional: sync to GitHub)
    ↓
GitHub (Optional Backup)
```

**You control everything. GitHub is staging. Gitea is production.**

---

## Next: Download the Package and Start

1. Download the `homelab-complete.zip` from this chat
2. Extract it locally
3. Follow this guide to set up GitHub
4. Customize your IPs/passwords locally
5. Push to GitHub
6. Run `./deploy.sh all`
7. Once Gitea is running, migrate to Gitea
8. You're done — everything is in Git on your tailnet

Ready?
