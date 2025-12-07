#!/bin/bash

# DigitalOcean Deployment Script for LiveKit - NO DOCKER VERSION
# Installs LiveKit and SIP server directly on the system

set -e

echo "🚀 LiveKit Direct Installation (No Docker)"
echo "=========================================="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "❌ Please run as root (use sudo)"
    exit 1
fi

# Get public IP
PUBLIC_IP=$(curl -s ifconfig.me || curl -s ipinfo.io/ip)
echo "📍 Detected Public IP: $PUBLIC_IP"
echo ""

# Step 1: Update system
echo "📦 Updating system packages..."
apt-get update
apt-get upgrade -y

# Step 2: Install Redis
echo ""
echo "📦 Installing Redis..."
apt-get install -y redis-server
systemctl enable redis-server
systemctl start redis-server

# Configure Redis to accept connections
sed -i 's/^bind 127.0.0.1/bind 0.0.0.0/' /etc/redis/redis.conf
sed -i 's/^protected-mode yes/protected-mode no/' /etc/redis/redis.conf
systemctl restart redis-server
echo "✅ Redis installed and configured"

# Step 3: Install LiveKit Server
echo ""
echo "📦 Installing LiveKit Server..."
curl -sSL https://get.livekit.io | bash
echo "✅ LiveKit Server installed"

# Step 4: Generate API credentials
echo ""
echo "🔐 Generating secure API credentials..."
API_KEY=$(openssl rand -hex 16)
API_SECRET=$(openssl rand -hex 32)
echo "API Key: $API_KEY"
echo "API Secret: $API_SECRET"
echo ""
echo "⚠️  IMPORTANT: Save these credentials!"
echo ""

# Step 5: Create LiveKit configuration
echo "⚙️  Creating LiveKit configuration..."
mkdir -p /etc/livekit
cat > /etc/livekit/livekit.yaml << EOF
port: 7880
bind_addresses:
  - ""

rtc:
  tcp_port: 7881
  port_range_start: 50000
  port_range_end: 60000
  use_external_ip: true
  stun_servers:
    - stun:stun.l.google.com:19302

redis:
  address: localhost:6379

keys:
  $API_KEY: $API_SECRET

log_level: info

room:
  empty_timeout: 5m
  max_duration: 0
EOF
echo "✅ LiveKit configuration created at /etc/livekit/livekit.yaml"

# Step 6: Create systemd service for LiveKit
echo ""
echo "⚙️  Creating LiveKit systemd service..."
cat > /etc/systemd/system/livekit.service << EOF
[Unit]
Description=LiveKit Server
After=network.target redis.service
Requires=redis.service

[Service]
Type=simple
ExecStart=/usr/local/bin/livekit-server --config /etc/livekit/livekit.yaml
Restart=always
RestartSec=5
User=root

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable livekit
systemctl start livekit
echo "✅ LiveKit service started"

# Step 7: Install LiveKit SIP Server
echo ""
echo "📦 Installing LiveKit SIP Server..."
# Determine architecture
ARCH=$(uname -m)
if [ "$ARCH" = "x86_64" ]; then
    ARCH="amd64"
elif [ "$ARCH" = "aarch64" ]; then
    ARCH="arm64"
else
    echo "❌ Unsupported architecture: $ARCH"
    exit 1
fi

# Try to get latest version from GitHub API, with fallback
SIP_VERSION=$(curl -s https://api.github.com/repos/livekit/sip/releases/latest 2>/dev/null | grep -oP '"tag_name": "\K[^"]+' | head -1)

# Fallback to a known working version if API fails
if [ -z "$SIP_VERSION" ]; then
    echo "⚠️  Could not fetch latest version, using v1.0.0"
    SIP_VERSION="v1.0.0"
fi

# Remove 'v' prefix if present for filename
SIP_VERSION_CLEAN=${SIP_VERSION#v}

echo "   Downloading SIP server version: $SIP_VERSION"

# Construct download URL
SIP_URL="https://github.com/livekit/sip/releases/download/${SIP_VERSION}/livekit-sip_${SIP_VERSION_CLEAN}_linux_${ARCH}.tar.gz"

# Download with error checking
if ! curl -L -f "$SIP_URL" -o /tmp/livekit-sip.tar.gz; then
    echo "❌ Failed to download SIP server from: $SIP_URL"
    echo "   Trying alternative method..."
    
    # Alternative: Try downloading the binary directly
    SIP_BINARY_URL="https://github.com/livekit/sip/releases/download/${SIP_VERSION}/livekit-sip_${SIP_VERSION_CLEAN}_linux_${ARCH}"
    if curl -L -f "$SIP_BINARY_URL" -o /usr/local/bin/livekit-sip; then
        chmod +x /usr/local/bin/livekit-sip
        echo "✅ LiveKit SIP Server installed (binary)"
    else
        echo "❌ Failed to download SIP server. Please install manually."
        echo "   Visit: https://github.com/livekit/sip/releases"
        exit 1
    fi
else
    # Extract if download succeeded
    if tar -xzf /tmp/livekit-sip.tar.gz -C /tmp 2>/dev/null; then
        if [ -f /tmp/livekit-sip ]; then
            mv /tmp/livekit-sip /usr/local/bin/
            chmod +x /usr/local/bin/livekit-sip
            rm -f /tmp/livekit-sip.tar.gz
            echo "✅ LiveKit SIP Server installed"
        else
            echo "❌ SIP binary not found in archive"
            exit 1
        fi
    else
        echo "❌ Failed to extract SIP server archive"
        exit 1
    fi
fi

# Step 8: Create SIP configuration
echo ""
echo "⚙️  Creating SIP configuration..."
mkdir -p /etc/livekit-sip
cat > /etc/livekit-sip/sip.yaml << EOF
livekit_url: ws://localhost:7880
livekit_api_key: $API_KEY
livekit_api_secret: $API_SECRET

redis:
  address: localhost:6379

sip:
  bind_address: "0.0.0.0"
  port: 5060
  domain: "$PUBLIC_IP"

rtp:
  port_range_start: 10000
  port_range_end: 20000
  use_external_ip: true
  external_ip: "$PUBLIC_IP"

log_level: info

number_cleanup:
  enabled: true
  rules:
    - pattern: "^\\\\+1"
      replacement: ""
    - pattern: "^1"
      replacement: ""
EOF
echo "✅ SIP configuration created at /etc/livekit-sip/sip.yaml"

# Step 9: Create systemd service for SIP
echo ""
echo "⚙️  Creating SIP systemd service..."
cat > /etc/systemd/system/livekit-sip.service << EOF
[Unit]
Description=LiveKit SIP Server
After=network.target redis.service livekit.service
Requires=redis.service livekit.service

[Service]
Type=simple
ExecStart=/usr/local/bin/livekit-sip --config /etc/livekit-sip/sip.yaml
Restart=always
RestartSec=5
User=root

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable livekit-sip
systemctl start livekit-sip
echo "✅ SIP service started"

# Step 10: Configure Firewall
echo ""
echo "🔥 Configuring Firewall..."
ufw allow 22/tcp    # SSH
ufw allow 7880/tcp  # LiveKit WebSocket
ufw allow 5060/tcp  # SIP TCP
ufw allow 5060/udp  # SIP UDP
ufw allow 10000:20000/udp  # RTP media
ufw allow 50000:60000/udp  # TURN/STUN
ufw --force enable > /dev/null 2>&1 || true
echo "✅ Firewall configured"

# Step 11: Wait for services to start
echo ""
echo "⏳ Waiting for services to start..."
sleep 5

# Step 12: Verify deployment
echo ""
echo "🔍 Verifying deployment..."
if systemctl is-active --quiet livekit; then
    echo "✅ LiveKit server is running"
else
    echo "⚠️  LiveKit server may not be running - check: systemctl status livekit"
fi

if systemctl is-active --quiet livekit-sip; then
    echo "✅ SIP server is running"
else
    echo "⚠️  SIP server may not be running - check: systemctl status livekit-sip"
fi

if systemctl is-active --quiet redis-server; then
    echo "✅ Redis is running"
else
    echo "⚠️  Redis may not be running - check: systemctl status redis-server"
fi

# Step 13: Display connection information
echo ""
echo "=========================================="
echo "✨ Deployment Complete!"
echo "=========================================="
echo ""
echo "📋 Connection Information:"
echo "   Public IP: $PUBLIC_IP"
echo "   LiveKit WebSocket: ws://$PUBLIC_IP:7880"
echo "   LiveKit HTTP: http://$PUBLIC_IP:7880"
echo "   SIP Server: sip://$PUBLIC_IP:5060"
echo ""
echo "🔑 API Credentials:"
echo "   API Key: $API_KEY"
echo "   API Secret: $API_SECRET"
echo ""
echo "📊 Useful Commands:"
echo "   View LiveKit logs: journalctl -u livekit -f"
echo "   View SIP logs: journalctl -u livekit-sip -f"
echo "   Check status: systemctl status livekit livekit-sip"
echo "   Restart services: systemctl restart livekit livekit-sip"
echo "   Stop services: systemctl stop livekit livekit-sip"
echo ""
echo "📁 Configuration Files:"
echo "   LiveKit: /etc/livekit/livekit.yaml"
echo "   SIP: /etc/livekit-sip/sip.yaml"
echo ""
echo "⚠️  IMPORTANT:"
echo "   - Save your API credentials from above"
echo "   - Services will auto-start on reboot"
echo ""

