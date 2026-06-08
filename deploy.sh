#!/bin/bash
# Master deployment orchestrator for homelab Kubernetes cluster
# Handles all four phases of deployment

set -e
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_err() { echo -e "${RED}[ERROR]${NC} $1"; }
header() { echo -e "\n${GREEN}=================================================================================${NC}\n${GREEN}  $1${NC}\n${GREEN}=================================================================================${NC}\n"; }

PHASE="${1:-help}"

case "$PHASE" in
    os)
        header "Phase 1: OS Setup with Ansible"
        [[ -z "$TS_AUTHKEY" ]] && { log_err "TS_AUTHKEY not set"; exit 1; }
        ansible-playbook -i ansible/inventory/hosts.yml ansible/site.yml
        log_info "OS setup complete. Verify Tailscale: ansible k8s_nodes -i ansible/inventory/hosts.yml -m command -a 'tailscale status'"
        ;;
    bootstrap)
        header "Phase 2: Kubernetes Bootstrap"
        ansible-playbook -i ansible/inventory/hosts.yml ansible/k8s-bootstrap.yml
        log_info "Kubernetes bootstrapped. Check: kubectl get nodes"
        ;;
    addons)
        header "Phase 2b: Install Cluster Addons"
        ansible-playbook -i ansible/inventory/hosts.yml ansible/k8s-install-addons.yml
        log_info "Addons installed. Next: Deploy services"
        ;;
    services)
        header "Phase 3: Deploy Services"
        kubectl apply -f k8s/base/namespaces.yaml
        kubectl apply -f k8s/base/storage-classes.yaml
        kubectl apply -f k8s/services/
        kubectl apply -f k8s/base/ingress.yaml
        log_info "Services deployed. Wait for pods: kubectl get pods -A"
        ;;
    verify)
        header "Cluster Health Check"
        echo "Nodes:"; kubectl get nodes
        echo -e "\nPods:"; kubectl get pods -A | head -20
        echo -e "\nStorage:"; kubectl get sc
        echo -e "\nServices:"; kubectl get svc -A
        ;;
    updates-check)
        header "Check for Available Updates"
        ansible-playbook -i ansible/inventory/hosts.yml ansible/updates-auto.yml
        ;;
    updates-cron)
        header "Setup Automated Update Monitoring"
        ansible-playbook -i ansible/inventory/hosts.yml ansible/updates-cron-setup.yml
        ;;
    k8s-upgrade)
        header "Kubernetes Upgrade"
        [[ -z "$K8S_VERSION" ]] && { log_err "Set K8S_VERSION=v1.31 ./deploy.sh k8s-upgrade"; exit 1; }
        ansible-playbook -i ansible/inventory/hosts.yml ansible/k8s-upgrade.yml -e upgrade_action=plan -e target_version=$K8S_VERSION
        ;;
    helm-check)
        header "Check Helm Chart Updates"
        ansible-playbook -i ansible/inventory/hosts.yml ansible/helm-updates.yml -e helm_action=check
        ;;
    helm-upgrade)
        header "Upgrade Helm Charts"
        ansible-playbook -i ansible/inventory/hosts.yml ansible/helm-updates.yml -e helm_action=upgrade
        ;;
    all)
        header "Running All Phases"
        [[ -z "$TS_AUTHKEY" ]] && { log_err "TS_AUTHKEY not set"; exit 1; }
        $0 os && $0 bootstrap && $0 addons && $0 services && $0 verify
        ;;
    *)
        cat << HELP
Homelab Kubernetes Deployment Script

Usage: ./deploy.sh [phase]

Deployment Phases:
    os          — Phase 1: OS setup
    bootstrap   — Phase 2: Kubernetes bootstrap
    addons      — Phase 2b: Install addons
    services    — Phase 3: Deploy services
    all         — Run all phases

Monitoring & Updates:
    verify      — Health check
    updates-check   — Check for available updates
    updates-cron    — Setup automated update monitoring
    helm-check      — Check available Helm updates
    helm-upgrade    — Upgrade Helm charts (CONFIRMATION REQUIRED)
    k8s-upgrade     — Kubernetes upgrade (CONFIRMATION REQUIRED)

Examples:
    TS_AUTHKEY=tskey-auth-xxx ./deploy.sh os
    ./deploy.sh bootstrap
    ./deploy.sh all
    ./deploy.sh updates-check
    K8S_VERSION=v1.31 ./deploy.sh k8s-upgrade
    ./deploy.sh helm-upgrade

Environment Variables:
    TS_AUTHKEY      Tailscale reusable auth key (required for 'os' phase)
                    Get from: https://login.tailscale.com/admin/settings/keys
    K8S_VERSION     Kubernetes target version for upgrade (e.g., v1.31)

For detailed documentation, see:
    README.md — Setup and deployment
    docs/UPDATE-MANAGEMENT.md — Update strategies

HELP
        ;;
esac
