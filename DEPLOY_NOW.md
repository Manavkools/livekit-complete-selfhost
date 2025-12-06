# 🚀 Deploy to DigitalOcean Droplet - RIGHT NOW

## Quick 3-Step Deployment

### Step 1: Create Droplet (2 minutes)
1. Go to: https://cloud.digitalocean.com/droplets/new
2. Settings:
   - **Image**: Ubuntu 22.04 (LTS) x64
   - **Plan**: 
     - Minimum: 4GB RAM / 2 vCPU ($24/month) - for testing
     - Recommended: 8GB RAM / 4 vCPU ($48/month) - for production
   - **Region**: Choose closest to your users
   - **Authentication**: SSH keys (add your key)
   - **Hostname**: `livekit-server` (optional)
3. Click **Create Droplet**
4. **Copy your droplet's IP address**

### Step 2: Deploy (3 minutes)
Copy and paste this entire block into your terminal:

```bash
# Connect to your droplet (replace YOUR_DROPLET_IP)
ssh root@YOUR_DROPLET_IP

# Clone repository (use your GitHub token if repo is private)
# Option 1: Public repo (no auth needed)
git clone https://github.com/Manavkools/livekit-complete-selfhost.git

# Option 2: If you need to use a token (replace YOUR_TOKEN)
# git clone https://YOUR_TOKEN@github.com/Manavkools/livekit-complete-selfhost.git

# Deploy
cd livekit-complete-selfhost && \
chmod +x deploy-digitalocean.sh && \
./deploy-digitalocean.sh
```

### Step 3: Get Your Credentials
After deployment completes, run:
```bash
cat .env
```

Save these credentials - you'll need them!

## ✅ You're Done!

Your LiveKit is now live at:
- **WebSocket**: `ws://YOUR_DROPLET_IP:7880`
- **HTTP**: `http://YOUR_DROPLET_IP:7880`
- **SIP**: `sip://YOUR_DROPLET_IP:5060`

## 🔍 Verify It's Working

From your local machine:
```bash
# Test LiveKit server
curl http://YOUR_DROPLET_IP:7880

# Check services are running (on droplet)
docker compose ps
```

## 📋 Quick Commands

```bash
# View logs
docker compose logs -f

# Restart services
docker compose restart

# Stop services
docker compose down

# Check status
docker compose ps
```

## 🆘 Troubleshooting

**Can't connect?**
- Check firewall: `ufw status`
- Verify ports are open in DigitalOcean dashboard
- Check logs: `docker compose logs`

**Services not starting?**
- Check Docker: `docker ps`
- View logs: `docker compose logs -f`

---

**That's it! Your LiveKit is live! 🎉**

