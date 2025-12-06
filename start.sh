#!/bin/bash

# LiveKit Self-Hosted Quick Start Script
# This script will start LiveKit server and SIP server in Docker

set -e

echo "🚀 Starting LiveKit Self-Hosted Setup..."
echo ""

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker first."
    echo "   Visit: https://docs.docker.com/get-docker/"
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo "❌ Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

# Create recordings directory if it doesn't exist
mkdir -p recordings

# Create .env file if it doesn't exist
if [ ! -f .env ]; then
    echo "📝 Creating .env file with default credentials..."
    cat > .env << EOF
LIVEKIT_API_KEY=devkey
LIVEKIT_API_SECRET=secret
EOF
    echo "✅ Created .env file"
fi

echo "🐳 Starting Docker containers..."
echo ""

# Use docker compose (v2) or docker-compose (v1)
if docker compose version &> /dev/null; then
    docker compose up -d
else
    docker-compose up -d
fi

echo ""
echo "⏳ Waiting for services to start..."
sleep 5

echo ""
echo "✅ LiveKit is starting up!"
echo ""
echo "📋 Service Information:"
echo "   - LiveKit Server: http://localhost:7880"
echo "   - LiveKit WebSocket: ws://localhost:7880"
echo "   - SIP Server: sip://localhost:5060"
echo ""
echo "🔑 API Credentials:"
echo "   - API Key: devkey"
echo "   - API Secret: secret"
echo ""
echo "📊 Check status with: docker compose ps"
echo "📝 View logs with: docker compose logs -f"
echo "🛑 Stop services with: docker compose down"
echo ""
echo "🌐 To access from other devices:"
echo "   - Replace 'localhost' with your machine's IP address"
echo "   - Ensure firewall allows ports: 7880, 5060, 10000-20000"
echo ""
echo "✨ Setup complete! Your LiveKit instance is running."

