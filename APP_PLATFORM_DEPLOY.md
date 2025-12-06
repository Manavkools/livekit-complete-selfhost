# Deploy to DigitalOcean App Platform

⚠️ **Important Limitation**: DigitalOcean App Platform has **limited UDP port support**, which is critical for SIP/RTP media streams. For full SIP functionality, we **strongly recommend using a Droplet** instead (see [DEPLOY_DIGITALOCEAN.md](./DEPLOY_DIGITALOCEAN.md)).

However, if you want to deploy LiveKit server (without full SIP support) on App Platform, follow these steps:

## 🚀 Quick Deploy to App Platform

### Option 1: Using App Spec File (Recommended)

1. **Go to DigitalOcean App Platform**
   - Navigate to [DigitalOcean App Platform](https://cloud.digitalocean.com/apps)
   - Click "Create App"

2. **Connect Repository**
   - Select "GitHub" as source
   - Choose repository: `Manavkools/livekit-complete-selfhost`
   - Branch: `main`

3. **Configure App**
   - App Platform should detect the `.do/app.yaml` file
   - If not detected, select "Edit App Spec" and paste the contents of `.do/app.yaml`

4. **Set Environment Variables**
   - Add these as secrets:
     - `LIVEKIT_API_KEY` (generate with: `openssl rand -hex 16`)
     - `LIVEKIT_API_SECRET` (generate with: `openssl rand -hex 32`)

5. **Deploy**
   - Click "Create Resources"
   - Wait for deployment to complete

### Option 2: Manual Configuration

If the app spec isn't detected:

1. **Add Redis Database**
   - Click "Add Resource" → "Database"
   - Choose Redis 7
   - Name: `redis`

2. **Add LiveKit Server Service**
   - Click "Add Service" → "Web Service"
   - Source: Your GitHub repo
   - Dockerfile: `Dockerfile.livekit`
   - HTTP Port: `7880`
   - Environment Variables:
     - `LIVEKIT_API_KEY` (as secret)
     - `LIVEKIT_API_SECRET` (as secret)
     - `REDIS_URL`: `${redis.DATABASE_URL}`
     - `LIVEKIT_KEYS`: `${LIVEKIT_API_KEY}:${LIVEKIT_API_SECRET}`

3. **Add SIP Server (Limited)**
   - Click "Add Service" → "Web Service"
   - Source: Your GitHub repo
   - Dockerfile: `Dockerfile.sip`
   - HTTP Port: `5060`
   - Environment Variables:
     - `LIVEKIT_URL`: `${livekit-server.PUBLIC_URL}`
     - `LIVEKIT_API_KEY` (as secret)
     - `LIVEKIT_API_SECRET` (as secret)
     - `REDIS_URL`: `${redis.DATABASE_URL}`

## ⚠️ Limitations

- **UDP Ports**: App Platform doesn't fully support UDP port ranges (10000-20000 for RTP)
- **SIP Functionality**: SIP calls may not work properly due to UDP limitations
- **TURN/STUN**: Limited support for TURN server functionality

## ✅ Recommended: Use Droplet Instead

For full functionality including SIP, use a **DigitalOcean Droplet**:
- See [QUICK_START_DO.md](./QUICK_START_DO.md) for 5-minute setup
- Full UDP support
- Complete SIP/RTP functionality
- More cost-effective for media streaming

## 📋 What Works on App Platform

✅ LiveKit WebSocket server  
✅ HTTP API  
✅ Basic LiveKit functionality  
❌ Full SIP server (UDP limitations)  
❌ RTP media streams  

## 🔗 Next Steps

1. **For Full Functionality**: Deploy to a Droplet using [deploy-digitalocean.sh](./deploy-digitalocean.sh)
2. **For App Platform**: Use the configuration above (with limitations)
3. **Hybrid Approach**: Run LiveKit on App Platform, SIP on Droplet

---

**Recommendation**: Use a Droplet for production deployments to ensure full SIP/RTP support.

