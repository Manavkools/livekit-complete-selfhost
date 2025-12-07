#!/bin/bash
# Quick fix script for incomplete installation

set -e

echo "🔧 Fixing LiveKit Installation..."
echo ""

# Your credentials
API_KEY="0d2c03e8f51436d2343ed68cb07c3afc"
API_SECRET="b8eff1527e6f92f7ece0e164f9887cf2f33fd53827091f5203bc48d9fc32f0d8"
PUBLIC_IP=$(curl -s ifconfig.me)

# Step 1: Complete Docker installation
echo "📦 Installing Docker..."
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    rm get-docker.sh
    systemctl enable docker
    systemctl start docker
    echo "✅ Docker installed and started"
else
    echo "✅ Docker already installed"
    systemctl start docker || true
fi

# Step 2: Check LiveKit service
echo ""
echo "🔍 Checking LiveKit service..."
if systemctl is-active --quiet livekit; then
    echo "✅ LiveKit is running"
else
    echo "⚠️  LiveKit is not running, checking logs..."
    journalctl -u livekit -n 20 --no-pager
    echo ""
    echo "Restarting LiveKit..."
    systemctl restart livekit
    sleep 3
    systemctl status livekit --no-pager -l
fi

# Step 3: Fix SIP service with proper Docker setup
echo ""
echo "⚙️  Setting up SIP server with Docker..."

# Create Docker wrapper script
cat > /usr/local/bin/livekit-sip-docker.sh << 'EOFSCRIPT'
#!/bin/bash
docker run --rm -i \
  --network host \
  -v /etc/livekit-sip/sip.yaml:/etc/sip.yaml:ro \
  -e LIVEKIT_URL=ws://localhost:7880 \
  -e LIVEKIT_API_KEY="${LIVEKIT_API_KEY}" \
  -e LIVEKIT_API_SECRET="${LIVEKIT_API_SECRET}" \
  -e REDIS_URL=redis://localhost:6379 \
  livekit/sip:latest \
  --config /etc/sip.yaml "$@"
EOFSCRIPT
chmod +x /usr/local/bin/livekit-sip-docker.sh

# Update SIP service file
cat > /etc/systemd/system/livekit-sip.service << EOFSERVICE
[Unit]
Description=LiveKit SIP Server
After=network.target redis.service livekit.service docker.service
Requires=redis.service livekit.service docker.service

[Service]
Type=simple
Environment="LIVEKIT_URL=ws://localhost:7880"
Environment="LIVEKIT_API_KEY=$API_KEY"
Environment="LIVEKIT_API_SECRET=$API_SECRET"
Environment="REDIS_URL=redis://localhost:6379"
ExecStart=/usr/local/bin/livekit-sip-docker.sh
Restart=always
RestartSec=5
User=root

[Install]
WantedBy=multi-user.target
EOFSERVICE

# Reload and start
systemctl daemon-reload
systemctl enable livekit-sip
systemctl start livekit-sip

# Step 4: Wait a moment and check status
echo ""
echo "⏳ Waiting for services to start..."
sleep 5

# Step 5: Final status check
echo ""
echo "=========================================="
echo "📊 Service Status"
echo "=========================================="
echo ""
systemctl status livekit --no-pager -l | head -15
echo ""
systemctl status livekit-sip --no-pager -l | head -15
echo ""
systemctl status redis-server --no-pager -l | head -10
echo ""

# Step 6: Display connection info
echo "=========================================="
echo "✨ Installation Fixed!"
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
echo ""

