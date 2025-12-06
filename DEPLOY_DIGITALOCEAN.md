# Deploy LiveKit to DigitalOcean

Complete guide to deploy LiveKit with SIP server on DigitalOcean in under 10 minutes.

## 🚀 Quick Deploy (10 Minutes)

### Prerequisites
- DigitalOcean account
- SSH key added to DigitalOcean

### Step 1: Create a DigitalOcean Droplet

1. Go to [DigitalOcean Dashboard](https://cloud.digitalocean.com/droplets/new)
2. Choose:
   - **Image**: Ubuntu 22.04 (LTS)
   - **Plan**: 
     - **Minimum**: 4GB RAM / 2 vCPU ($24/month) - for testing
     - **Recommended**: 8GB RAM / 4 vCPU ($48/month) - for production
   - **Region**: Choose closest to your users
   - **Authentication**: SSH keys
   - **Hostname**: `livekit-server` (or your choice)

3. Click **Create Droplet**

### Step 2: Connect to Your Droplet

```bash
ssh root@YOUR_DROPLET_IP
```

Replace `YOUR_DROPLET_IP` with your droplet's IP address.

### Step 3: Install Docker and Docker Compose

Run these commands on your droplet:

```bash
# Update system
apt-get update && apt-get upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# Install Docker Compose
apt-get install docker-compose-plugin -y

# Verify installation
docker --version
docker compose version
```

### Step 4: Clone and Setup

```bash
# Clone the repository
git clone https://github.com/Manavkools/livekit-complete-selfhost.git
cd livekit-complete-selfhost

# Create .env file with secure credentials
cat > .env << EOF
LIVEKIT_API_KEY=$(openssl rand -hex 16)
LIVEKIT_API_SECRET=$(openssl rand -hex 32)
EOF

# Create recordings directory
mkdir -p recordings
```

### Step 5: Configure for Production

Update `livekit.yaml` to use external IP:

```bash
# Get your droplet's public IP
PUBLIC_IP=$(curl -s ifconfig.me)

# Update livekit.yaml
sed -i "s/use_external_ip: false/use_external_ip: true/" livekit.yaml
sed -i "/stun_servers:/a\    - stun:stun.l.google.com:19302" livekit.yaml
```

Update `sip.yaml`:

```bash
# Update sip.yaml with your public IP
sed -i "s/domain: \"sip.livekit.local\"/domain: \"$PUBLIC_IP\"/" sip.yaml
sed -i "s/use_external_ip: false/use_external_ip: true/" sip.yaml
sed -i "/external_ip:/a\  external_ip: \"$PUBLIC_IP\"" sip.yaml
```

### Step 6: Configure Firewall

```bash
# Allow required ports
ufw allow 22/tcp    # SSH
ufw allow 7880/tcp  # LiveKit WebSocket
ufw allow 5060/tcp  # SIP TCP
ufw allow 5060/udp  # SIP UDP
ufw allow 10000:20000/udp  # RTP media
ufw allow 50000:60000/udp  # TURN/STUN

# Enable firewall
ufw --force enable
ufw status
```

### Step 7: Start Services

```bash
# Start all services
docker compose up -d

# Check status
docker compose ps

# View logs
docker compose logs -f
```

### Step 8: Verify Deployment

```bash
# Check if services are running
curl http://localhost:7880

# Check from your local machine
curl http://YOUR_DROPLET_IP:7880
```

## 📋 Your LiveKit Endpoints

After deployment, you'll have:

- **LiveKit WebSocket**: `ws://YOUR_DROPLET_IP:7880`
- **LiveKit HTTP**: `http://YOUR_DROPLET_IP:7880`
- **SIP Server**: `sip://YOUR_DROPLET_IP:5060`

## 🔐 Security Best Practices

### 1. Change Default Credentials

The `.env` file was created with random keys. Keep them secure!

### 2. Set Up a Domain (Optional but Recommended)

1. Point your domain to the droplet IP:
   ```
   A record: livekit.yourdomain.com -> YOUR_DROPLET_IP
   A record: sip.yourdomain.com -> YOUR_DROPLET_IP
   ```

2. Update configurations:
   ```bash
   # Update sip.yaml domain
   sed -i "s/domain: \".*\"/domain: \"sip.yourdomain.com\"/" sip.yaml
   ```

### 3. Enable SSL/TLS (Recommended)

Use a reverse proxy like Nginx with Let's Encrypt:

```bash
# Install Nginx
apt-get install nginx certbot python3-certbot-nginx -y

# Create Nginx config
cat > /etc/nginx/sites-available/livekit << EOF
server {
    listen 80;
    server_name livekit.yourdomain.com;

    location / {
        proxy_pass http://localhost:7880;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

# Enable site
ln -s /etc/nginx/sites-available/livekit /etc/nginx/sites-enabled/
nginx -t
systemctl reload nginx

# Get SSL certificate
certbot --nginx -d livekit.yourdomain.com
```

### 4. Set Up Automatic Updates

```bash
# Enable automatic security updates
apt-get install unattended-upgrades -y
dpkg-reconfigure -plow unattended-upgrades
```

## 🔄 Maintenance Commands

```bash
# View logs
docker compose logs -f

# Restart services
docker compose restart

# Stop services
docker compose down

# Update to latest images
docker compose pull
docker compose up -d

# Check resource usage
docker stats
```

## 📊 Monitoring

### Check System Resources

```bash
# CPU and Memory
htop

# Disk usage
df -h

# Docker resource usage
docker stats
```

### Set Up Monitoring (Optional)

Consider using:
- DigitalOcean Monitoring (built-in)
- Prometheus + Grafana
- Uptime monitoring services

## 🐛 Troubleshooting

### Services won't start
```bash
# Check logs
docker compose logs

# Check if ports are in use
netstat -tulpn | grep -E '7880|5060'

# Restart Docker
systemctl restart docker
```

### Can't connect from outside
```bash
# Check firewall
ufw status

# Check if services are listening
netstat -tulpn

# Test from droplet
curl http://localhost:7880
```

### High resource usage
```bash
# Check what's using resources
docker stats

# Consider upgrading droplet size
```

## 💰 Cost Optimization

- **Development/Testing**: 4GB RAM droplet ($24/month)
- **Production (Small)**: 8GB RAM droplet ($48/month)
- **Production (Medium)**: 16GB RAM droplet ($96/month)

## 📚 Next Steps

1. ✅ Test your LiveKit connection
2. ✅ Test SIP connectivity
3. ✅ Set up domain and SSL
4. ✅ Configure monitoring
5. ✅ Set up backups for recordings

## 🔗 Useful Links

- [DigitalOcean Documentation](https://docs.digitalocean.com/)
- [LiveKit Documentation](https://docs.livekit.io/)
- [Docker Documentation](https://docs.docker.com/)

---

**Your LiveKit instance is now live on DigitalOcean!** 🎉

