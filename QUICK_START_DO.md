# 🚀 Quick Start: Deploy to DigitalOcean (5 Minutes)

## Step 1: Create Droplet
1. Go to [DigitalOcean](https://cloud.digitalocean.com/droplets/new)
2. Choose: **Ubuntu 22.04**, **4GB RAM** (minimum), **SSH keys**
3. Click **Create Droplet**

## Step 2: Connect & Deploy
```bash
# Connect to your droplet
ssh root@YOUR_DROPLET_IP

# Clone repository
git clone https://github.com/Manavkools/livekit-complete-selfhost.git
cd livekit-complete-selfhost

# Run deployment script
chmod +x deploy-digitalocean.sh
./deploy-digitalocean.sh
```

## Step 3: Done! 🎉
Your LiveKit is now live at:
- **WebSocket**: `ws://YOUR_DROPLET_IP:7880`
- **SIP**: `sip://YOUR_DROPLET_IP:5060`

Check credentials in `.env` file.

---

For detailed instructions, see [DEPLOY_DIGITALOCEAN.md](./DEPLOY_DIGITALOCEAN.md)

