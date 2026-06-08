# Kubernetes Service Manifests

Service deployments for:
- pihole.yaml — DNS ad-blocker
- vaultwarden.yaml — Password manager
- gitea.yaml — Git server
- postgres.yaml — Shared database
- nextcloud.yaml — File sync + Redis
- immich.yaml — Photo library with ML
- audiobookshelf.yaml — Audiobooks/podcasts

**Before deploying:**
1. Replace `yourdomain.ts.net` with your Tailscale hostname
2. Replace all `CHANGEME` passwords with strong passwords
3. Set appropriate resource requests/limits for your hardware

**Deploy all:**
```bash
kubectl apply -f k8s/services/
```

Full manifests are available in the original package from @Claude.
