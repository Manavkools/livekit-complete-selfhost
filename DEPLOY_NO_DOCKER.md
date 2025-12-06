# Deploy LiveKit Without Docker

This guide shows you how to deploy LiveKit directly on your system without Docker. This approach is lighter weight and gives you more control.

## 🚀 Quick Deploy (No Docker)

### On Your DigitalOcean Droplet:

```bash
# Download and run the no-docker deployment script
curl -fsSL https://raw.githubusercontent.com/Manavkools/livekit-complete-selfhost/main/deploy-no-docker.sh -o deploy-no-docker.sh
chmod +x deploy-no-docker.sh
./deploy-no-docker.sh
```

Or if you've cloned the repo:

```bash
cd livekit-complete-selfhost
chmod +x deploy-no-docker.sh
./deploy-no-docker.sh
```

## ✅ What Gets Installed

- **LiveKit Server** - Installed via official installer
- **LiveKit SIP Server** - Downloaded from GitHub releases
- **Redis** - Installed via apt
- **Systemd Services** - Auto-start on boot

## 📋 Advantages of No-Docker Approach

✅ **Lighter weight** - No Docker overhead  
✅ **Direct control** - Easier to customize  
✅ **Systemd integration** - Native service management  
✅ **Better performance** - No containerization overhead  
✅ **Easier debugging** - Direct access to processes  

## 📋 Advantages of Docker Approach

✅ **Isolation** - Services are isolated  
✅ **Easy updates** - Just pull new images  
✅ **Consistency** - Same environment everywhere  
✅ **Easy cleanup** - Remove containers easily  

## 🔧 Management Commands

### Check Status
```bash
systemctl status livekit
systemctl status livekit-sip
systemctl status redis-server
```

### View Logs
```bash
# LiveKit logs
journalctl -u livekit -f

# SIP logs
journalctl -u livekit-sip -f

# Redis logs
journalctl -u redis-server -f
```

### Restart Services
```bash
systemctl restart livekit
systemctl restart livekit-sip
```

### Stop Services
```bash
systemctl stop livekit
systemctl stop livekit-sip
```

### Start Services
```bash
systemctl start livekit
systemctl start livekit-sip
```

## 📁 Configuration Files

- **LiveKit Config**: `/etc/livekit/livekit.yaml`
- **SIP Config**: `/etc/livekit-sip/sip.yaml`
- **Redis Config**: `/etc/redis/redis.conf`

## 🔄 Updating

### Update LiveKit Server
```bash
curl -sSL https://get.livekit.io | bash
systemctl restart livekit
```

### Update SIP Server
```bash
# Get latest version
SIP_VERSION=$(curl -s https://api.github.com/repos/livekit/sip/releases/latest | grep tag_name | cut -d '"' -f 4)
ARCH=$(uname -m)
[ "$ARCH" = "x86_64" ] && ARCH="amd64" || ARCH="arm64"

# Download and install
curl -L "https://github.com/livekit/sip/releases/download/${SIP_VERSION}/livekit-sip_${SIP_VERSION#v}_linux_${ARCH}.tar.gz" -o /tmp/livekit-sip.tar.gz
tar -xzf /tmp/livekit-sip.tar.gz -C /tmp
mv /tmp/livekit-sip /usr/local/bin/
systemctl restart livekit-sip
```

## 🆘 Troubleshooting

### Service won't start
```bash
# Check logs
journalctl -u livekit -n 50
journalctl -u livekit-sip -n 50

# Check if ports are in use
netstat -tulpn | grep -E '7880|5060'
```

### Can't connect from outside
```bash
# Check firewall
ufw status

# Check if services are listening
netstat -tulpn | grep livekit
```

## 🆚 Docker vs No-Docker Comparison

| Feature | Docker | No-Docker |
|---------|--------|-----------|
| Setup Complexity | Medium | Low |
| Resource Usage | Higher | Lower |
| Isolation | High | Low |
| Updates | Easy (pull images) | Manual |
| Debugging | Container logs | System logs |
| Portability | High | Medium |

**Choose Docker if**: You want isolation, easy updates, and consistency.  
**Choose No-Docker if**: You want lighter weight, direct control, and better performance.

---

Both approaches work great! Choose what fits your needs.

