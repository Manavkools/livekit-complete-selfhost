#!/bin/bash

# DigitalOcean Deployment Script for LiveKit
# Run this script on your DigitalOcean droplet after initial setup

set -e

echo "🚀 LiveKit DigitalOcean Deployment Script"
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

# Step 4: Create .env if it doesn't exist
if [ ! -f .env ]; then
    echo ""
    echo "🔐 Generating secure API credentials..."
    cat > .env << EOF
LIVEKIT_API_KEY=$(openssl rand -hex 16)
LIVEKIT_API_SECRET=$(openssl rand -hex 32)
EOF
    echo "✅ Created .env file with secure credentials"
    echo "⚠️  IMPORTANT: Save these credentials securely!"
    cat .env
else
    echo "✅ .env file already exists"
fi

# Step 5: Update configurations for production
echo ""
echo "⚙️  Configuring for production..."

# Update livekit.yaml
if [ -f livekit.yaml ]; then
    # Enable external IP
    sed -i 's/use_external_ip: false/use_external_ip: true/' livekit.yaml 2>/dev/null || true
    
    # Add STUN servers if not present
    if ! grep -q "stun_servers:" livekit.yaml; then
        sed -i '/use_external_ip: true/a\  stun_servers:\n    - stun:stun.l.google.com:19302' livekit.yaml
    fi
    
    echo "✅ Updated livekit.yaml"
fi

# Update sip.yaml
if [ -f sip.yaml ]; then
    # Update domain
    sed -i "s/domain: \".*\"/domain: \"$PUBLIC_IP\"/" sip.yaml 2>/dev/null || true
    
    # Enable external IP
    sed -i 's/use_external_ip: false/use_external_ip: true/' sip.yaml 2>/dev/null || true
    
    # Add external IP if not present
    if ! grep -q "external_ip:" sip.yaml; then
        sed -i "/use_external_ip: true/a\  external_ip: \"$PUBLIC_IP\"" sip.yaml
    fi
    
    echo "✅ Updated sip.yaml"
fi

# Step 6: Create recordings directory
mkdir -p recordings
echo "✅ Created recordings directory"

# Step 7: Start services
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

# Step 8: Verify deployment
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

# Step 9: Display connection information
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
echo "🔑 API Credentials (from .env):"
cat .env | grep -v "^#"
echo ""
echo "📊 Useful Commands:"
echo "   View logs: docker compose logs -f"
echo "   Check status: docker compose ps"
echo "   Restart: docker compose restart"
echo "   Stop: docker compose down"
echo ""
echo "⚠️  IMPORTANT:"
echo "   - Save your API credentials from .env file"
echo "   - Configure firewall rules if needed"
echo "   - Consider setting up SSL/TLS with a domain"
echo ""
echo "📚 See DEPLOY_DIGITALOCEAN.md for more details"
echo ""

