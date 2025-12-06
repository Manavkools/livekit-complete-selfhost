#!/bin/bash

# Direct Deployment Script for DigitalOcean Droplet
# Copy and paste this entire script if you can't clone the repo

set -e

echo "🚀 LiveKit Direct Deployment Script"
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

# Step 1: Install Docker
if ! command -v docker &> /dev/null; then
    echo "📦 Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    rm get-docker.sh
    echo "✅ Docker installed"
else
    echo "✅ Docker already installed"
fi

# Step 2: Install Docker Compose
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo "📦 Installing Docker Compose..."
    apt-get update
    apt-get install -y docker-compose-plugin
    echo "✅ Docker Compose installed"
else
    echo "✅ Docker Compose already installed"
fi

# Step 3: Configure Firewall
echo ""
echo "🔥 Configuring Firewall..."
ufw allow 22/tcp    # SSH
ufw allow 7880/tcp  # LiveKit WebSocket
ufw allow 5060/tcp  # SIP TCP
ufw allow 5060/udp  # SIP UDP
ufw allow 10000:20000/udp  # RTP media
ufw allow 50000:60000/udp  # TURN/STUN

# Enable firewall if not already enabled
ufw --force enable > /dev/null 2>&1 || true
echo "✅ Firewall configured"

# Step 4: Create project directory
PROJECT_DIR="/opt/livekit"
mkdir -p $PROJECT_DIR
cd $PROJECT_DIR

# Step 5: Create .env file
echo ""
echo "🔐 Generating secure API credentials..."
cat > .env << 'EOF'
LIVEKIT_API_KEY=devkey
LIVEKIT_API_SECRET=secret
EOF

# Generate secure credentials
API_KEY=$(openssl rand -hex 16)
API_SECRET=$(openssl rand -hex 32)
cat > .env << EOF
LIVEKIT_API_KEY=$API_KEY
LIVEKIT_API_SECRET=$API_SECRET
EOF
echo "✅ Created .env file with secure credentials"
echo "⚠️  IMPORTANT: Save these credentials!"
cat .env

# Step 6: Create livekit.yaml
echo ""
echo "⚙️  Creating LiveKit configuration..."
cat > livekit.yaml << EOF
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
  address: redis:6379

log_level: info

room:
  empty_timeout: 5m
  max_duration: 0
EOF
echo "✅ Created livekit.yaml"

# Step 7: Create sip.yaml
echo "⚙️  Creating SIP configuration..."
cat > sip.yaml << EOF
livekit_url: ws://livekit-server:7880
livekit_api_key: \${LIVEKIT_API_KEY}
livekit_api_secret: \${LIVEKIT_API_SECRET}

redis:
  address: redis:6379

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
echo "✅ Created sip.yaml"

# Step 8: Create docker-compose.yml
echo "⚙️  Creating Docker Compose configuration..."
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  redis:
    image: redis:7-alpine
    container_name: livekit-redis
    ports:
      - "6379:6379"
    volumes:
      - redis-data:/data
    command: redis-server --appendonly yes
    restart: unless-stopped
    networks:
      - livekit-network

  livekit-server:
    image: livekit/livekit-server:latest
    container_name: livekit-server
    ports:
      - "7880:7880"
      - "7881:7881"
      - "7882:7882"
      - "50000-60000:50000-60000/udp"
    volumes:
      - ./livekit.yaml:/etc/livekit.yaml:ro
      - ./recordings:/recordings
    env_file:
      - .env
    environment:
      - LIVEKIT_KEYS=${LIVEKIT_API_KEY}:${LIVEKIT_API_SECRET}
    command: --config /etc/livekit.yaml
    restart: unless-stopped
    depends_on:
      - redis
    networks:
      - livekit-network

  sip-server:
    image: livekit/sip:latest
    container_name: livekit-sip
    ports:
      - "5060:5060/udp"
      - "5060:5060/tcp"
      - "10000-20000:10000-20000/udp"
    volumes:
      - ./sip.yaml:/etc/sip.yaml:ro
    env_file:
      - .env
    environment:
      - LIVEKIT_URL=ws://livekit-server:7880
      - LIVEKIT_API_KEY=${LIVEKIT_API_KEY}
      - LIVEKIT_API_SECRET=${LIVEKIT_API_SECRET}
      - REDIS_URL=redis://redis:6379
    command: --config /etc/sip.yaml
    restart: unless-stopped
    depends_on:
      - livekit-server
      - redis
    networks:
      - livekit-network

volumes:
  redis-data:

networks:
  livekit-network:
    driver: bridge
EOF
echo "✅ Created docker-compose.yml"

# Step 9: Create recordings directory
mkdir -p recordings
echo "✅ Created recordings directory"

# Step 10: Start services
echo ""
echo "🐳 Starting Docker containers..."
if docker compose version &> /dev/null; then
    docker compose up -d
else
    docker-compose up -d
fi

echo ""
echo "⏳ Waiting for services to start..."
sleep 10

# Step 11: Verify deployment
echo ""
echo "🔍 Verifying deployment..."
if docker ps | grep -q livekit-server; then
    echo "✅ LiveKit server is running"
else
    echo "⚠️  LiveKit server may not be running"
fi

if docker ps | grep -q livekit-sip; then
    echo "✅ SIP server is running"
else
    echo "⚠️  SIP server may not be running"
fi

if docker ps | grep -q livekit-redis; then
    echo "✅ Redis is running"
else
    echo "⚠️  Redis may not be running"
fi

# Step 12: Display connection information
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
cat .env
echo ""
echo "📊 Useful Commands:"
echo "   View logs: cd $PROJECT_DIR && docker compose logs -f"
echo "   Check status: cd $PROJECT_DIR && docker compose ps"
echo "   Restart: cd $PROJECT_DIR && docker compose restart"
echo "   Stop: cd $PROJECT_DIR && docker compose down"
echo ""
echo "⚠️  IMPORTANT:"
echo "   - Save your API credentials from above"
echo "   - All files are in: $PROJECT_DIR"
echo ""

