# LiveKit Self-Hosted Setup

Complete self-hosted LiveKit server with SIP server support. Get up and running in under 10 minutes!

## 🚀 Quick Start (10 Minutes)

### Prerequisites

- Docker and Docker Compose installed
  - [Install Docker](https://docs.docker.com/get-docker/)
  - Docker Compose is included with Docker Desktop

### Step 1: Clone/Download this repository

```bash
cd complete-livekit-selfhost
```

### Step 2: Start the services

**Option A: Using the quick start script (Recommended)**
```bash
chmod +x start.sh
./start.sh
```

**Option B: Using Docker Compose directly**
```bash
docker compose up -d
```

### Step 3: Verify services are running

```bash
docker compose ps
```

You should see three services running:
- `livekit-redis` - Redis cache
- `livekit-server` - LiveKit server
- `livekit-sip` - SIP server

### Step 4: Test your setup

- **LiveKit Server**: `http://localhost:7880`
- **WebSocket URL**: `ws://localhost:7880`
- **SIP Server**: `sip://localhost:5060`

## 📋 Configuration

### Default Credentials

- **API Key**: `devkey`
- **API Secret**: `secret`

⚠️ **Important**: Change these credentials for production use!

### Environment Variables

Edit `.env` file to customize:
```env
LIVEKIT_API_KEY=your-api-key
LIVEKIT_API_SECRET=your-api-secret
```

### Port Configuration

Default ports:
- **7880**: LiveKit WebSocket/HTTP
- **7881**: LiveKit TCP
- **5060**: SIP signaling (UDP/TCP)
- **10000-20000**: RTP media (UDP)
- **50000-60000**: TURN/STUN (UDP)

### Network Access

To access from other devices on your network:

1. Find your machine's IP address:
   ```bash
   # macOS/Linux
   ifconfig | grep "inet "
   
   # Or
   ip addr show
   ```

2. Update configuration:
   - In `livekit.yaml`, set `use_external_ip: true` and configure `stun_servers`
   - In `sip.yaml`, set `use_external_ip: true` and set `external_ip` to your public IP

3. Ensure firewall allows:
   - Port 7880 (LiveKit)
   - Port 5060 (SIP)
   - Ports 10000-20000 (RTP media)
   - Ports 50000-60000 (TURN)

## 🔧 Advanced Configuration

### LiveKit Server (`livekit.yaml`)

Key settings:
- `port`: WebSocket port (default: 7880)
- `rtc.port_range_start/end`: TURN port range
- `redis.address`: Redis connection
- `keys`: API key/secret pairs

### SIP Server (`sip.yaml`)

Key settings:
- `sip.domain`: SIP domain name
- `sip.bind_address`: Bind address (0.0.0.0 for all interfaces)
- `rtp.port_range_start/end`: RTP media port range
- `rtp.use_external_ip`: Enable if behind NAT

## 📊 Monitoring & Logs

### View logs
```bash
# All services
docker compose logs -f

# Specific service
docker compose logs -f livekit-server
docker compose logs -f sip-server
```

### Check status
```bash
docker compose ps
```

### Restart services
```bash
docker compose restart
```

## 🛑 Stopping Services

```bash
docker compose down
```

To also remove volumes (⚠️ deletes data):
```bash
docker compose down -v
```

## 🔐 Production Deployment

### 1. Generate Secure API Keys

```bash
# Generate secure API key
openssl rand -hex 16

# Generate secure API secret
openssl rand -hex 32
```

Update `.env` file with these values.

### 2. Configure External IP

If deploying on a server with a public IP:

1. Update `livekit.yaml`:
   ```yaml
   rtc:
     use_external_ip: true
     stun_servers:
       - stun:stun.l.google.com:19302
   ```

2. Update `sip.yaml`:
   ```yaml
   rtp:
     use_external_ip: true
     external_ip: "your.public.ip.address"
   ```

### 3. Configure Firewall

Ensure these ports are open:
- **7880**: LiveKit WebSocket
- **5060**: SIP signaling
- **10000-20000**: RTP media
- **50000-60000**: TURN/STUN

### 4. Use Domain Name (Optional)

Instead of IP addresses, configure DNS:
- Point a domain to your server IP
- Update `sip.yaml` with your domain:
  ```yaml
  sip:
    domain: "sip.yourdomain.com"
  ```

## 🧪 Testing

### Test LiveKit Connection

Use the LiveKit test page or connect via SDK:
- WebSocket URL: `ws://your-server:7880`
- API Key: (from `.env`)
- API Secret: (from `.env`)

### Test SIP Connection

Use a SIP client (e.g., Linphone, Zoiper):
- SIP URI: `sip:your-server-ip:5060`
- Or: `sip:username@your-server-ip:5060`

## 📚 Resources

- [LiveKit Documentation](https://docs.livekit.io/)
- [LiveKit SIP Server Docs](https://docs.livekit.io/home/self-hosting/sip-server/)
- [LiveKit GitHub](https://github.com/livekit/livekit)
- [LiveKit SIP GitHub](https://github.com/livekit/sip)

## 🐛 Troubleshooting

### Services won't start
- Check Docker is running: `docker ps`
- Check ports aren't in use: `lsof -i :7880`
- View logs: `docker compose logs`

### Can't connect from other devices
- Verify firewall settings
- Check `bind_address` is `0.0.0.0` (not `127.0.0.1`)
- Ensure `use_external_ip` is configured correctly

### SIP calls not working
- Verify SIP port 5060 is open
- Check RTP port range 10000-20000 is open
- Review SIP server logs: `docker compose logs sip-server`

## 📝 License

This setup uses LiveKit which is licensed under Apache 2.0.

## 🤝 Support

For issues:
- [LiveKit Discord](https://livekit.io/discord)
- [LiveKit GitHub Issues](https://github.com/livekit/livekit/issues)

---

**Ready to go!** Your LiveKit instance should now be running. 🎉

