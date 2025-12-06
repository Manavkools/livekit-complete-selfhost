# 🚀 Quick Deploy - No Git Clone Needed

If you're having issues cloning the repository, use this **one-command deployment**:

## Option 1: Make Repository Public (Easiest)

1. Go to: https://github.com/Manavkools/livekit-complete-selfhost/settings
2. Scroll down to "Danger Zone"
3. Click "Change visibility" → "Make public"
4. Then clone normally:
   ```bash
   git clone https://github.com/Manavkools/livekit-complete-selfhost.git
   cd livekit-complete-selfhost
   chmod +x deploy-digitalocean.sh
   ./deploy-digitalocean.sh
   ```

## Option 2: Download Script Directly (If Repo is Public)

```bash
# Download and run deployment script
curl -fsSL https://raw.githubusercontent.com/Manavkools/livekit-complete-selfhost/main/deploy-digitalocean.sh -o deploy-digitalocean.sh && \
chmod +x deploy-digitalocean.sh && \
./deploy-digitalocean.sh
```

## Option 3: Use Direct Deployment Script

Copy and paste this entire script into your droplet:

```bash
curl -fsSL https://raw.githubusercontent.com/Manavkools/livekit-complete-selfhost/main/DIRECT_DEPLOY.sh | bash
```

Or if that doesn't work, download it first:

```bash
curl -fsSL https://raw.githubusercontent.com/Manavkools/livekit-complete-selfhost/main/DIRECT_DEPLOY.sh -o deploy.sh
chmod +x deploy.sh
./deploy.sh
```

---

**Recommended**: Make the repository public (Option 1) for easiest deployment.

